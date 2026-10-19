package ir.psdkjoon.komak

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri

object DeepLinkHandler {
    val scheme = "komak".replace('_', '-')

    @Volatile
    private var pending: String? = null

    fun uri(host: String, path: String): Uri =
        Uri.Builder().scheme(scheme).authority(host).appendPath(path).build()

    fun handle(intent: Intent?): Boolean {
        if (intent == null || intent.action != Intent.ACTION_VIEW) return false
        val data = intent.data ?: return false
        if (data.scheme != scheme && data.scheme != "https") return false
        pending = data.toString()
        return true
    }

    fun consume(): String? {
        val link = pending
        pending = null
        return link
    }

    fun setWebLinksEnabled(context: Context, enabled: Boolean) {
        context.packageManager.setComponentEnabledSetting(
            ComponentName(context, "ir.psdkjoon.komak.WebLink"),
            if (enabled) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            },
            PackageManager.DONT_KILL_APP,
        )
    }
}
