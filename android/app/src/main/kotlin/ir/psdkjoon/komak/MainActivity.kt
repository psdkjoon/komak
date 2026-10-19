package ir.psdkjoon.komak

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return EngineHolder.ensure(context)
    }

    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        Hosts.claim(this)
        super.onCreate(savedInstanceState)
        EngineHolder.activity = this
        if (savedInstanceState == null) handleIncoming(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIncoming(intent)
    }

    override fun onPostResume() {
        super.onPostResume()
        EngineHolder.activity = this
        EngineHolder.installIfWaiting()
    }

    private var taskLabel: String? = null
    private var taskColor = 0

    /**
     * Flutter sets the recent-apps title and color but no icon, so Android falls back
     * to the icon baked into the APK. Add the launcher icon that is enabled now.
     */
    @Suppress("DEPRECATION")
    override fun setTaskDescription(taskDescription: ActivityManager.TaskDescription?) {
        if (taskDescription != null) {
            taskLabel = taskDescription.label
            taskColor = taskDescription.primaryColor
        }
        super.setTaskDescription(withIcon(taskLabel, taskColor))
    }

    fun refreshTaskDescription() {
        super.setTaskDescription(withIcon(taskLabel, taskColor))
    }

    @Suppress("DEPRECATION")
    private fun withIcon(label: String?, color: Int): ActivityManager.TaskDescription {
        val icon = LauncherIcon.currentIconRes(this)
        return if (android.os.Build.VERSION.SDK_INT >= 33) {
            ActivityManager.TaskDescription.Builder()
                .setLabel(label)
                .setIcon(icon)
                .setPrimaryColor(color)
                .build()
        } else {
            ActivityManager.TaskDescription(label, icon, color)
        }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        FileService.onResult(this, requestCode, resultCode, data)
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        PermissionService.onResult(requestCode, grantResults)
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    override fun onDestroy() {
        if (EngineHolder.activity === this) EngineHolder.activity = null
        super.onDestroy()
    }

    private fun handleIncoming(intent: Intent?) {
        DeepLinkHandler.handle(intent)
        ShareService.handle(this, intent)
    }
}
