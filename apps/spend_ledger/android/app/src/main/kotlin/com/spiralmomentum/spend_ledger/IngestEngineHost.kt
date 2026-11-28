package com.spiralmomentum.spend_ledger

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * 리스너 서비스가 쓰는 백그라운드 FlutterEngine 하나를 관리한다.
 * 첫 요청 때 엔진을 띄워 Dart `androidIngestMain`을 실행하고, `ready`가 오기 전 요청은 큐에 쌓는다.
 * 준비 10초, 응답 15초 제한. 실패한 엔진은 버리고 다음 요청 때 새로 띄운다.
 * 모든 상태는 메인 스레드에서만 바꾼다. 원문은 로그·진단에 남기지 않는다.
 */
object IngestEngineHost {
    private const val TAG = "IngestEngineHost"
    private const val CHANNEL = "spend_ledger/ingest"
    private const val ENTRYPOINT = "androidIngestMain"

    /** 진입점이 정의된 라이브러리. 생략하면 lib/main.dart에서 찾아 실행되지 않는다. */
    private const val ENTRYPOINT_LIBRARY = "package:spend_ledger/app/ingest_entry.dart"
    private const val READY_TIMEOUT_MS = 10_000L
    private const val INGEST_TIMEOUT_MS = 15_000L

    /** 엔진으로 넘길 요청. [atMs]는 진단의 `at`, [startElapsed]는 소요 시간 기준. */
    private sealed class Job {
        val atMs: Long = System.currentTimeMillis()
        val startElapsed: Long = SystemClock.elapsedRealtime()

        class Ingest(val message: ExtractedMessage) : Job()
        class Refresh : Job()
    }

    private val main = Handler(Looper.getMainLooper())
    private lateinit var appContext: Context
    private var engine: FlutterEngine? = null
    private var channel: MethodChannel? = null

    /** 엔진마다 하나씩 늘려, 버린 엔진의 늦은 `ready`·응답을 무시한다. */
    private var generation = 0
    private val queue = IngestQueue<Job> { deliver(it) }
    private val readyTimeout = Runnable { onReadyTimeout() }

    /** 결제 알림 한 건을 Dart로 넘긴다. 어느 스레드에서 불러도 된다. */
    fun submit(context: Context, message: ExtractedMessage) {
        enqueue(context, Job.Ingest(message))
    }

    /** 날짜가 바뀌면 요약·위젯을 다시 계산하게 한다. */
    fun refresh(context: Context) {
        enqueue(context, Job.Refresh())
    }

    /** 서비스가 끝날 때 엔진을 버린다. 쌓인 요청은 진단에 남기고 버린다. */
    fun shutdown() {
        main.post {
            if (!::appContext.isInitialized) return@post
            discardEngine().forEach { record(it, null, "service-stopped") }
        }
    }

    private fun enqueue(context: Context, job: Job) {
        val app = context.applicationContext
        main.post {
            appContext = app
            if (!queue.isReady && engine == null && !startEngine()) {
                record(job, null, "engine-run-failed")
                return@post
            }
            queue.submit(job)
        }
    }

    /** 엔진을 띄운다. 이미 띄우는 중이면 그대로 둔다. 실행에 실패하면 false. */
    private fun startEngine(): Boolean {
        val gen = ++generation
        return try {
            val loader = FlutterInjector.instance().flutterLoader()
            if (!loader.initialized()) loader.startInitialization(appContext)
            loader.ensureInitializationComplete(appContext, null)
            val created = FlutterEngine(appContext)
            val ch = MethodChannel(created.dartExecutor.binaryMessenger, CHANNEL)
            ch.setMethodCallHandler { call, result ->
                if (call.method == "ready") {
                    if (gen == generation) onReady()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
            engine = created
            channel = ch
            main.postDelayed(readyTimeout, READY_TIMEOUT_MS)
            created.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(loader.findAppBundlePath(), ENTRYPOINT_LIBRARY, ENTRYPOINT),
            )
            true
        } catch (t: Throwable) {
            Log.w(TAG, "engine start failed: ${t.javaClass.simpleName}")
            discardEngine()
            false
        }
    }

    private fun onReady() {
        main.removeCallbacks(readyTimeout)
        queue.markReady()
    }

    private fun onReadyTimeout() {
        Log.w(TAG, "ready timeout")
        discardEngine().forEach { record(it, null, "ready-timeout") }
    }

    /** 엔진을 버리고 아직 넘기지 못한 요청을 돌려준다. */
    private fun discardEngine(): List<Job> {
        main.removeCallbacks(readyTimeout)
        generation++
        channel?.setMethodCallHandler(null)
        try {
            engine?.destroy()
        } catch (t: Throwable) {
            Log.w(TAG, "engine destroy failed: ${t.javaClass.simpleName}")
        }
        engine = null
        channel = null
        return queue.reset()
    }

    private fun deliver(job: Job) {
        val ch = channel ?: run {
            record(job, null, "engine-run-failed")
            return
        }
        val gen = generation
        val engineMs = SystemClock.elapsedRealtime() - job.startElapsed
        var done = false
        fun finish(dartMs: Long?, result: String, failed: Boolean) {
            if (done) return
            done = true
            record(job, engineMs, result, dartMs)
            // 응답이 없거나 채널이 깨진 엔진은 버린다. 다음 요청이 새로 띄운다.
            if (failed && gen == generation) {
                discardEngine().forEach { record(it, null, "engine-discarded") }
            }
        }
        val timeout = Runnable {
            finish(null, if (job is Job.Refresh) "timeout" else "ingest-timeout", true)
        }
        main.postDelayed(timeout, INGEST_TIMEOUT_MS)
        val (method, args) = when (job) {
            is Job.Ingest -> "ingest" to mapOf(
                "text" to job.message.text,
                "sender" to job.message.sender,
                "package" to job.message.packageName,
                "postedAtMs" to job.message.postedAtMs,
            )
            is Job.Refresh -> "refresh" to null
        }
        ch.invokeMethod(method, args, object : MethodChannel.Result {
            override fun success(reply: Any?) {
                main.removeCallbacks(timeout)
                val map = reply as? Map<*, *>
                if (map == null) {
                    finish(null, "error:unexpected-reply", false)
                    return
                }
                val dartMs = (map["dartMs"] as? Number)?.toLong()
                val result = map["result"] as? String ?: "unknown"
                val label = if (result == "error") "error:${map["error"] as? String ?: "unknown"}" else result
                finish(dartMs, label, false)
            }

            override fun error(code: String, message: String?, details: Any?) {
                main.removeCallbacks(timeout)
                finish(null, "error:$code", true)
            }

            override fun notImplemented() {
                main.removeCallbacks(timeout)
                finish(null, "error:not-implemented", true)
            }
        })
    }

    private fun record(job: Job, engineMs: Long?, result: String, dartMs: Long? = null) {
        val total = SystemClock.elapsedRealtime() - job.startElapsed
        val label = if (job is Job.Refresh) "refresh:$result" else result
        try {
            NativeStores.recordDiagnostic(
                appContext,
                atMs = job.atMs,
                engineMs = engineMs ?: total,
                dartMs = dartMs,
                totalMs = total,
                result = label,
            )
        } catch (t: Throwable) {
            Log.w(TAG, "diagnostic write failed: ${t.javaClass.simpleName}")
        }
    }
}
