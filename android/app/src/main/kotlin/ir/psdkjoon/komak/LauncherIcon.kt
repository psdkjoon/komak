package ir.psdkjoon.komak

import android.app.Activity
import android.app.Application
import android.content.ComponentCallbacks
import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.content.res.Resources
import android.os.Bundle
import android.os.Handler
import android.os.Looper

/**
 * Keeps the launcher icon in step with the app's theme mode and accent color.
 *
 * The manifest has one `activity-alias` per accent and theme (`IconMauveMocha`,
 * `IconBlueLatte`, ...). Exactly one is enabled at a time. Dart only reports the
 * user's choice ([configure]); everything else lives here so it keeps working while
 * the UI is not:
 *
 * - An OS theme change is picked up through [ComponentCallbacks], so it works while
 *   the app is in the background, which a Dart lifecycle observer cannot do.
 * - An accent that arrives from a sibling app ([adoptSynced]) is applied right away,
 *   in the receiver's process, without waiting for the user to open this app.
 * - The swap never happens while one of our activities is visible. Some launchers
 *   close the app when its icon changes, so the change waits until the user leaves.
 *
 * Android has no way to change the icon Settings shows on the app's info page: that
 * one is baked into the APK (see `appIcon` in `app/build.gradle.kts`). The launcher
 * and the recent-apps list do follow the alias, see [currentIconRes].
 */
object LauncherIcon {
    private const val PREFS = "launcher_icon"
    private const val PREFIX = "Icon"
    private const val AFTER_STOP_MS = 600L
    private const val AFTER_REQUEST_MS = 800L
    private const val AFTER_START_MS = 1500L

    private lateinit var app: Application
    private val main = Handler(Looper.getMainLooper())

    @Volatile
    private var installed = false

    @Volatile
    private var started = 0
    private var aliases: List<String>? = null

    private val settle = Runnable { if (started == 0) apply() }

    fun install(application: Application) {
        if (installed) return
        installed = true
        app = application

        application.registerActivityLifecycleCallbacks(object : Application.ActivityLifecycleCallbacks {
            override fun onActivityStarted(activity: Activity) {
                started++
                main.removeCallbacks(settle)
            }

            override fun onActivityStopped(activity: Activity) {
                started = (started - 1).coerceAtLeast(0)
                if (started == 0) later(AFTER_STOP_MS)
            }

            override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}
            override fun onActivityResumed(activity: Activity) {}
            override fun onActivityPaused(activity: Activity) {}
            override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
            override fun onActivityDestroyed(activity: Activity) {}
        })

        application.registerComponentCallbacks(object : ComponentCallbacks {
            override fun onConfigurationChanged(newConfig: Configuration) = later(AFTER_REQUEST_MS)

            override fun onLowMemory() {}
        })

        // A process that starts without a UI (a receiver, the boot service) may have
        // missed a theme change while it was dead. Catch up, unless the user is
        // opening the app right now: starting an activity cancels this.
        later(AFTER_START_MS)
    }

    /** Called from Dart whenever the theme mode or the accent changes. */
    @Synchronized
    fun configure(mode: String, accent: String, updatedAt: Long) {
        if (!installed) return
        val prefs = app.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        // Dart may still hold an older accent or theme than the ones a sibling app
        // just sent us (it has not pulled yet). The newest choice wins.
        if (accent.isNotEmpty() && updatedAt >= prefs.getLong("accentAt", 0L)) {
            prefs.edit()
                .putString("mode", mode)
                .putString("accent", accent)
                .putLong("accentAt", updatedAt)
                .commit()
        }
        later(AFTER_REQUEST_MS)
    }

    /**
     * An accent that came in from a sibling app. Runs on any thread and swaps the icon
     * at once when no screen of ours is open.
     */
    @Synchronized
    fun adoptSynced(accent: String, mode: String, updatedAt: Long) {
        if (!installed || accent.isEmpty()) return
        val prefs = app.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (updatedAt < prefs.getLong("accentAt", 0L)) return
        val edit = prefs.edit().putString("accent", accent).putLong("accentAt", updatedAt)
        if (mode.isNotEmpty()) edit.putString("mode", mode)
        edit.commit()
        if (started == 0) apply()
    }

    /**
     * The launcher icon that is enabled right now, as a drawable resource, or the
     * static app icon before the first switch. Used for the recent-apps entry and the
     * app shortcuts, which would otherwise keep showing the icon baked into the APK.
     */
    fun currentIconRes(context: Context): Int {
        val applied = context.applicationContext
            .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString("applied", null)
        if (applied != null) {
            val body = applied.removePrefix(PREFIX)
            val variant = if (body.endsWith("Mocha")) "mocha" else "latte"
            val accent = body.removeSuffix("Mocha").removeSuffix("Latte").lowercase()
            val id = context.resources.getIdentifier(
                "ic_launcher_${accent}_$variant",
                "mipmap",
                context.packageName,
            )
            if (id != 0) return id
        }
        return R.mipmap.ic_launcher
    }

    private fun later(delayMs: Long) {
        main.removeCallbacks(settle)
        if (started == 0) main.postDelayed(settle, delayMs)
    }

    @Synchronized
    private fun apply() {
        val prefs = app.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val accent = prefs.getString("accent", null) ?: return
        if (accent.isEmpty() || !accent.all { it in 'a'..'z' }) return
        val dark = when (prefs.getString("mode", "system")) {
            "dark" -> true
            "light" -> false
            else -> {
                val night = Resources.getSystem().configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
                night == Configuration.UI_MODE_NIGHT_YES
            }
        }
        val target = PREFIX + accent.replaceFirstChar { it.uppercase() } +
            if (dark) "Mocha" else "Latte"
        if (!switchTo(target)) return
        if (prefs.getString("applied", null) != target) {
            prefs.edit().putString("applied", target).commit()
            main.post {
                ShortcutService.refreshIcons(app)
                (EngineHolder.activity as? MainActivity)?.refreshTaskDescription()
            }
        }
    }

    /** Returns false when there is no such alias, so nothing was changed. */
    private fun switchTo(target: String): Boolean {
        val pm = app.packageManager
        val all = aliases ?: scanAliases(pm).also { aliases = it }
        val wanted = all.filter { it.substringAfterLast('.') == target }
        if (wanted.isEmpty()) return false
        val others = all - wanted.toSet()

        // Enable first, then disable, so there is never a moment with no icon.
        for (name in wanted) setState(pm, name, true)
        for (name in others) setState(pm, name, false)
        return true
    }

    private fun setState(pm: PackageManager, name: String, enable: Boolean) {
        val component = ComponentName(app.packageName, name)
        val current = try {
            pm.getComponentEnabledSetting(component)
        } catch (_: IllegalArgumentException) {
            return
        }
        val enabledNow = when (current) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED -> false
            else -> manifestDefault(pm, component)
        }
        if (enabledNow == enable) return
        pm.setComponentEnabledSetting(
            component,
            if (enable) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            },
            PackageManager.DONT_KILL_APP,
        )
    }

    @Suppress("DEPRECATION")
    private fun manifestDefault(pm: PackageManager, component: ComponentName): Boolean {
        return try {
            pm.getActivityInfo(component, PackageManager.GET_DISABLED_COMPONENTS).enabled
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    /** Every `Icon*` alias the manifest declares, so Kotlin needs no list of accents. */
    @Suppress("DEPRECATION")
    private fun scanAliases(pm: PackageManager): List<String> {
        val info = try {
            pm.getPackageInfo(
                app.packageName,
                PackageManager.GET_ACTIVITIES or PackageManager.GET_DISABLED_COMPONENTS,
            )
        } catch (_: PackageManager.NameNotFoundException) {
            return emptyList()
        }
        return info.activities.orEmpty()
            .filter { it.targetActivity != null && it.name.substringAfterLast('.').startsWith(PREFIX) }
            .map { it.name }
    }
}
