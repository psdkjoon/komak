package ir.psdkjoon.komak

import android.app.Application
import androidx.work.Configuration
import java.io.File
import java.util.Date

class MainApplication : Application(), Configuration.Provider {
    // The theme-sync provider runs in a second process (see ThemeSync). Tell WorkManager
    // which one is the real one so it does not set itself up twice.
    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder().setDefaultProcessName(packageName).build()

    override fun onCreate() {
        super.onCreate()
        // The ":sync" process only answers sibling apps. It must stay light: no engine.
        if (ThemeSync.isSyncProcess()) return
        logCrashes()
        LauncherIcon.install(this)
        ThemeSync.watchInstalls(this)
        EngineHolder.ensure(this)
    }

    // Writes an uncaught native error to the same errors.log the Dart side uses
    // (About > Diagnostics), then lets Android handle the crash as usual.
    private fun logCrashes() {
        val previous = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, error ->
            try {
                File(filesDir, "errors.log").appendText(
                    "--- ${Date()} [native]\n${error.stackTraceToString()}\n",
                )
            } catch (_: Exception) {
            }
            previous?.uncaughtException(thread, error)
        }
    }
}
