package com.spiralmomentum.spend_ledger

import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "spend_ledger/android").setMethodCallHandler { call, result ->
            when (call.method) {
                "setAllowedPackages" -> {
                    val packages = call.argument<List<String>>("packages")
                    if (packages == null) {
                        result.error("bad-args", "packages is required", null)
                    } else {
                        NativeStores.setAllowedPackages(this, packages)
                        result.success(null)
                    }
                }
                "listenerEnabled" -> result.success(
                    NotificationManagerCompat.getEnabledListenerPackages(this).contains(packageName),
                )
                "openListenerSettings" -> {
                    startActivity(
                        Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                    )
                    result.success(null)
                }
                "recentPackages" -> result.success(
                    NativeStores.recentPackages(this).map { mapOf("package" to it, "label" to label(it)) },
                )
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "spend_ledger/diagnostics").setMethodCallHandler { call, result ->
            when (call.method) {
                "list" -> result.success(NativeStores.diagnosticsJson(this))
                else -> result.notImplemented()
            }
        }
    }

    /** 앱 이름. 조회할 수 없으면 패키지 이름. */
    private fun label(pkg: String): String = try {
        val pm = packageManager
        pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString()
    } catch (e: PackageManager.NameNotFoundException) {
        pkg
    }
}
