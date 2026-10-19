package ir.psdkjoon.komak

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import java.io.File
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

object EngineHolder {
    private lateinit var appContext: Context

    private var engine: FlutterEngine? = null
    private var tileChannel: MethodChannel? = null
    private var themeSyncChannel: MethodChannel? = null
    private var pendingToggle = false
    private var pendingInstall: File? = null

    @Volatile
    var activity: android.app.Activity? = null

    fun ensure(context: Context): FlutterEngine {
        engine?.let { return it }
        appContext = context.applicationContext
        val created = FlutterEngine(appContext)
        setUpChannels(created)
        created.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault(),
        )
        engine = created
        return created
    }

    fun toggleFromTile(context: Context) {
        if (engine != null) {
            tileChannel?.invokeMethod("toggleRequested", null)
            return
        }
        pendingToggle = true
        ensure(context)
    }

    private fun setUpChannels(e: FlutterEngine) {
        val messenger = e.dartExecutor.binaryMessenger

        SoundChannel.register(e, appContext)

        MethodChannel(messenger, "komak/paths").setMethodCallHandler { call, result ->
            when (call.method) {
                "resolve" -> result.success(
                    mapOf(
                        "nativeLibraryDir" to appContext.applicationInfo.nativeLibraryDir,
                        "filesDir" to appContext.filesDir.absolutePath,
                    ),
                )
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "komak/launcher_icon").setMethodCallHandler { call, result ->
            when (call.method) {
                "configure" -> {
                    LauncherIcon.configure(
                        call.argument<String>("mode") ?: "system",
                        call.argument<String>("accent") ?: "",
                        call.argument<Number>("updatedAt")?.toLong() ?: 0L,
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        val themeSync = MethodChannel(messenger, "komak/theme_sync")
        themeSyncChannel = themeSync
        themeSync.setMethodCallHandler { call, result ->
            when (call.method) {
                "publish" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    val accent = call.argument<String>("accent") ?: ""
                    val mode = call.argument<String>("mode") ?: "system"
                    val updatedAt = call.argument<Number>("updatedAt")?.toLong() ?: 0L
                    ThemeSync.async(result) {
                        ThemeSync.toMap(ThemeSync.publish(appContext, enabled, accent, mode, updatedAt))
                    }
                }
                "pull" -> ThemeSync.async(result) {
                    ThemeSync.toMap(ThemeSync.pull(appContext))
                }
                "current" -> ThemeSync.async(result) {
                    ThemeSync.toMap(ThemeSync.current(appContext))
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "komak/system").setMethodCallHandler { call, result ->
            when (call.method) {
                "openUrl" -> openUrl(call.argument<String>("url"), result)
                "installApk" -> installApk(call.argument<String>("path"), result)
                "abi" -> result.success(Build.SUPPORTED_ABIS.firstOrNull())
                "requestNotifications" -> {
                    requestNotifications()
                    result.success(null)
                }
                "notify" -> {
                    notify(
                        call.argument<String>("title") ?: "",
                        call.argument<String>("body") ?: "",
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "komak/files").setMethodCallHandler { call, result ->
            when (call.method) {
                "pick" -> {
                    val types = call.argument<List<String>>("types") ?: listOf("*/*")
                    val started = FileService.pickFile(activity, types) { paths ->
                        result.success(paths.firstOrNull())
                    }
                    if (!started) result.success(null)
                }
                "saveToDownloads" -> {
                    val name = call.argument<String>("name") ?: "file"
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes == null) {
                        result.error("no_data", "Nothing to save.", null)
                    } else {
                        val saved = FileService.saveToDownloads(appContext, bytes, name)
                        result.success(saved != null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        val tile = MethodChannel(messenger, "komak/tile")
        tileChannel = tile
        tile.setMethodCallHandler { call, result ->
            when (call.method) {
                "enable" -> {
                    setTileEnabled(true)
                    result.success(null)
                }
                "setState" -> {
                    QuickTileService.setState(
                        appContext,
                        call.argument<String>("state") ?: "off",
                    )
                    result.success(null)
                }
                "consumeToggle" -> {
                    val value = pendingToggle
                    pendingToggle = false
                    result.success(value)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openUrl(url: String?, result: MethodChannel.Result) {
        if (url == null) {
            result.error("bad_url", "No URL.", null)
            return
        }
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            appContext.startActivity(intent)
            result.success(null)
        } catch (e: Exception) {
            result.error("no_browser", "No app can open this link.", null)
        }
    }

    private fun canInstall(): Boolean =
        Build.VERSION.SDK_INT < 26 ||
            appContext.packageManager.canRequestPackageInstalls()

    private fun installApk(path: String?, result: MethodChannel.Result) {
        val file = path?.let { File(it) }
        if (file == null || !file.isFile) {
            result.error("no_file", "The update file is missing.", null)
            return
        }
        try {
            if (canInstall()) {
                pendingInstall = null
                launchInstaller(file)
                result.success("installing")
            } else {
                pendingInstall = file
                appContext.startActivity(
                    Intent(
                        Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                        Uri.parse("package:${appContext.packageName}"),
                    ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                )
                result.success("needs_permission")
            }
        } catch (e: Exception) {
            pendingInstall = null
            result.error("install_failed", e.message ?: "Could not start the installer.", null)
        }
    }

    fun installIfWaiting() {
        val file = pendingInstall ?: return
        pendingInstall = null
        if (!canInstall()) return
        try {
            launchInstaller(file)
        } catch (_: Exception) {
        }
    }

    private fun launchInstaller(file: File) {
        val uri = FileProvider.getUriForFile(appContext, "${appContext.packageName}.updates", file)
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, "application/vnd.android.package-archive")
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        appContext.startActivity(intent)
    }

    private fun requestNotifications() {
        if (Build.VERSION.SDK_INT < 33) return
        val host = activity ?: return
        if (host.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        host.requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 0)
    }

    private fun notify(title: String, body: String) {
        NotificationHelper.notify(appContext, title, body)
    }

    private fun setTileEnabled(enabled: Boolean) {
        appContext.packageManager.setComponentEnabledSetting(
            ComponentName(appContext, "ir.psdkjoon.komak.QuickTileService"),
            if (enabled) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            },
            PackageManager.DONT_KILL_APP,
        )
    }

    fun requestThemeSync(context: Context, done: () -> Unit) {
        ensure(context)
        val channel = themeSyncChannel
        if (channel == null) {
            done()
            return
        }
        channel.invokeMethod(
            "refresh",
            null,
            object : MethodChannel.Result {
                override fun success(result: Any?) = done()
                override fun error(code: String, message: String?, details: Any?) = done()
                override fun notImplemented() = done()
            },
        )
    }
}
