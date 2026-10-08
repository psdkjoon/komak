package ir.psdkjoon.komak

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            startService(Intent(this, IconService::class.java))
        } catch (_: Exception) {
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ir.psdkjoon.komak/app_icon")
            .setMethodCallHandler { call, result ->
                if (call.method == "setPendingIcon") {
                    IconSwitcher.setPending(this, call.argument<Boolean>("dark") ?: false)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        if (isFinishing) {
            IconSwitcher.applyPending(this)
        }
        super.onDestroy()
    }
}
