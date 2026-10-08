package ir.psdkjoon.komak

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager

object IconSwitcher {
    private const val PREFS = "komak_icon"
    private const val PENDING = "pending_dark"
    private const val APPLIED = "applied_dark"

    fun setPending(context: Context, dark: Boolean) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putBoolean(PENDING, dark).apply()
    }

    fun applyPending(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.contains(PENDING)) return
        val dark = prefs.getBoolean(PENDING, false)
        if (prefs.getBoolean(APPLIED, false) == dark) return
        val pm = context.packageManager
        val main = ComponentName(context, MainActivity::class.java)
        val darkAlias = ComponentName(context, "ir.psdkjoon.komak.DarkLauncher")
        val enable = if (dark) darkAlias else main
        val disable = if (dark) main else darkAlias
        pm.setComponentEnabledSetting(enable, PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP)
        pm.setComponentEnabledSetting(disable, PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP)
        prefs.edit().putBoolean(APPLIED, dark).apply()
    }
}
