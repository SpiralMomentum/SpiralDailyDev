package com.spiralmomentum.spend_ledger

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

/** 처음 허용하는 알림 앱. Dart `defaultNotificationPackages`와 같다. */
val defaultAllowedPackages: Set<String> = setOf(
    "com.samsung.android.messaging",
    "com.google.android.apps.messaging",
)

const val DIAGNOSTIC_LIMIT = 20
const val RECENT_LIMIT = 20

/**
 * 진단 JSON 배열 문자열 뒤에 [entry]를 더하고 최근 [limit]건만 남긴다(가장 오래된 것부터 버림).
 * 기존 값이 없거나 깨졌으면 새로 시작한다. 값이 null인 필드는 넣지 않는다.
 * 필드는 iOS와 같은 `{at, path, engineMs, dartMs?, totalMs, result}`이고, 순서는 Dart가 `at`으로 정렬한다.
 */
fun appendDiagnostic(existingJson: String?, entry: Map<String, Any?>, limit: Int = DIAGNOSTIC_LIMIT): String {
    val existing = existingJson?.let {
        try {
            JSONArray(it)
        } catch (e: JSONException) {
            null
        }
    } ?: JSONArray()
    val items = (0 until existing.length()).mapNotNull { existing.optJSONObject(it) }
    val next = JSONObject()
    entry.forEach { (k, v) -> if (v != null) next.put(k, v) }
    val kept = (items + next).takeLast(limit)
    return JSONArray().apply { kept.forEach { put(it) } }.toString()
}

/** 최근 알림 앱 목록 맨 앞에 [pkg]를 두고(중복 제거) 최근 [limit]개만 남긴다. */
fun pushRecent(existing: List<String>, pkg: String, limit: Int = RECENT_LIMIT): List<String> =
    (listOf(pkg) + existing.filter { it != pkg }).take(limit)

/**
 * 네이티브 저장소. 패키지 이름과 진단 수치만 저장한다. 문자 원문은 절대 넣지 않는다(NFR-01).
 * 리스너 서비스(메인 스레드)와 앱 엔진 채널(메인 스레드)이 함께 쓰므로 갱신은 동기화한다.
 */
object NativeStores {
    private const val PREFS = "spend_ledger_native"
    private const val KEY_ALLOWED = "allowed_packages"
    private const val KEY_RECENT = "recent_packages"
    private const val KEY_DIAGNOSTICS = "ingest_diagnostics"
    private const val SEP = "\n"

    private fun prefs(context: Context): SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** 저장된 허용 앱. 한 번도 저장하지 않았으면 기본 2개. 빈 목록 저장은 그대로 빈 목록이다. */
    fun allowedPackages(context: Context): Set<String> =
        prefs(context).getStringSet(KEY_ALLOWED, null)?.toSet() ?: defaultAllowedPackages

    fun setAllowedPackages(context: Context, packages: List<String>) {
        prefs(context).edit().putStringSet(KEY_ALLOWED, packages.toSet()).apply()
    }

    fun recentPackages(context: Context): List<String> =
        prefs(context).getString(KEY_RECENT, null)
            ?.split(SEP)
            ?.filter { it.isNotEmpty() }
            ?: emptyList()

    @Synchronized
    fun pushRecentPackage(context: Context, pkg: String) {
        val current = recentPackages(context)
        if (current.firstOrNull() == pkg) return
        prefs(context).edit()
            .putString(KEY_RECENT, pushRecent(current, pkg).joinToString(SEP))
            .apply()
    }

    fun diagnosticsJson(context: Context): String =
        prefs(context).getString(KEY_DIAGNOSTICS, null) ?: "[]"

    @Synchronized
    fun recordDiagnostic(
        context: Context,
        atMs: Long,
        engineMs: Long,
        dartMs: Long?,
        totalMs: Long,
        result: String,
    ) {
        val p = prefs(context)
        val entry = mapOf<String, Any?>(
            "at" to atMs,
            "path" to "listener",
            "engineMs" to engineMs,
            "dartMs" to dartMs,
            "totalMs" to totalMs,
            "result" to result,
        )
        p.edit().putString(KEY_DIAGNOSTICS, appendDiagnostic(p.getString(KEY_DIAGNOSTICS, null), entry)).apply()
    }
}
