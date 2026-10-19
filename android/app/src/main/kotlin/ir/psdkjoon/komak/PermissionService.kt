package ir.psdkjoon.komak

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings

object PermissionService {
    const val NOTIFICATIONS = "android.permission.POST_NOTIFICATIONS"

    private const val FIRST_CODE = 4200
    private const val CODE_COUNT = 100

    private val callbacks = HashMap<Int, (Boolean) -> Unit>()
    private var counter = 0

    fun has(context: Context, permission: String): Boolean {
        if (permission == NOTIFICATIONS && Build.VERSION.SDK_INT < 33) return true
        if (Build.VERSION.SDK_INT < 23) return true
        return context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
    }

    fun request(activity: Activity?, permissions: List<String>, callback: (Boolean) -> Unit) {
        if (activity == null) {
            callback(false)
            return
        }
        val missing = permissions.filter { !has(activity, it) }
        if (missing.isEmpty()) {
            callback(true)
            return
        }
        val code = FIRST_CODE + counter % CODE_COUNT
        counter++
        callbacks[code] = callback
        activity.requestPermissions(missing.toTypedArray(), code)
    }

    fun onResult(requestCode: Int, grantResults: IntArray): Boolean {
        val callback = callbacks.remove(requestCode) ?: return false
        callback(grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED })
        return true
    }

    fun shouldExplain(activity: Activity, permission: String): Boolean =
        Build.VERSION.SDK_INT >= 23 && activity.shouldShowRequestPermissionRationale(permission)

    fun openSettings(context: Context): Boolean {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.parse("package:${context.packageName}"),
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            context.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }
}
