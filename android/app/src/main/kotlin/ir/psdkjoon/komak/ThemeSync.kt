package ir.psdkjoon.komak

import android.annotation.SuppressLint
import android.app.Application
import android.content.BroadcastReceiver
import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import android.os.Binder
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean
import org.json.JSONObject

/**
 * Shares the accent color between every app built from this template on one phone.
 *
 * Each app keeps its choice in `files/theme_sync.json` (accent, a timestamp of when the
 * user picked it, and whether syncing is on) and serves it through a read-only content
 * provider. When the user picks an accent, the app tells its siblings with a broadcast
 * and each sibling pulls the newest value. Newest timestamp wins. A freshly installed
 * app pulls once when it starts. An app that is already running also wakes a newly
 * installed sibling at once ([watchInstalls]), so that one need not be opened first.
 *
 * Apps find each other through [ACTION_PROVIDER] and only trust an app signed with the
 * same key as themselves.
 *
 * The provider runs in its own `:sync` process, so a sibling asking for the color does
 * not start this app's Flutter engine. [MainApplication] skips the engine there.
 */
object ThemeSync {
    // Must be identical in every app. It is also written in AndroidManifest.xml.
    const val ACTION_PROVIDER = "ir.psdkjoon.action.THEME_SYNC"
    const val ACTION_POKE = "ir.psdkjoon.action.THEME_SYNC_POKE"

    private const val FILE = "theme_sync.json"
    private const val SYNC_PROCESS = ":sync"

    /** [mode] is "system", "light" or "dark", or empty when an older sibling did not send one. */
    data class State(val accent: String, val mode: String, val updatedAt: Long)

    private data class Stored(val enabled: Boolean, val state: State)

    private val lock = Any()
    private val worker by lazy { java.util.concurrent.Executors.newSingleThreadExecutor() }
    private val main = Handler(Looper.getMainLooper())

    fun isSyncProcess(): Boolean {
        return try {
            File("/proc/self/cmdline").readText().trimEnd('\u0000').endsWith(SYNC_PROCESS)
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Stores the app's own choice and tells the siblings when it is new.
     * Returns the newest state this app knows, or null while syncing is off.
     */
    fun publish(context: Context, enabled: Boolean, accent: String, mode: String, updatedAt: Long): State? {
        if (!valid(accent)) return null
        var fresh = false
        val result = synchronized(lock) {
            val previous = read(context)
            val known = previous?.state?.updatedAt ?: -1L
            val state = if (previous == null || updatedAt >= known) {
                State(accent, if (validMode(mode)) mode else "system", updatedAt)
            } else {
                previous.state
            }
            fresh = enabled && updatedAt > known && updatedAt > 0
            write(context, Stored(enabled, state))
            state
        }
        if (fresh) pokePeers(context)
        return if (enabled) result else null
    }

    /**
     * The look this app already holds, without asking any sibling: one small file read.
     * [pull] may have stored a newer one while Dart was not running, so Dart asks for
     * this before its first frame. Returns null while syncing is off.
     */
    fun current(context: Context): State? {
        val own = synchronized(lock) { read(context) } ?: return null
        return if (own.enabled) own.state else null
    }

    /**
     * Asks every sibling for its color and keeps the newest. Blocking: call off the main
     * thread. Works on a fresh install too: before Dart has ever run there is no file of
     * our own yet, and the first sibling that has a choice is taken as it is.
     */
    fun pull(context: Context): State? {
        val own = synchronized(lock) { read(context) }
        if (own != null && !own.enabled) return null
        var newest = own?.state
        for (peer in peers(context)) {
            val state = query(context, peer) ?: continue
            if (state.updatedAt > (newest?.updatedAt ?: 0L)) newest = state
        }
        val found = newest ?: return null
        // An older sibling sends no theme. Keep ours rather than resetting it.
        val best = if (found.mode.isEmpty()) {
            found.copy(mode = own?.state?.mode ?: "system")
        } else {
            found
        }
        if (best != own?.state) {
            synchronized(lock) {
                val latest = read(context)
                if (latest == null || best.updatedAt > latest.state.updatedAt) {
                    write(context, Stored(latest?.enabled ?: true, best))
                }
            }
        }
        // Change the launcher icon now, in this process, instead of waiting for Dart
        // (which may not be running) or for the user to open the app.
        LauncherIcon.adoptSynced(best.accent, best.mode, best.updatedAt)
        return best
    }

    /** Runs [work] on a background thread and delivers the result on the main thread. */
    fun async(result: MethodChannel.Result, work: () -> Map<String, Any>?) {
        worker.execute {
            val value = try {
                work()
            } catch (_: Exception) {
                null
            }
            main.post { result.success(value) }
        }
    }

    fun toMap(state: State?): Map<String, Any>? {
        return state?.let { mapOf("accent" to it.accent, "mode" to it.mode, "updatedAt" to it.updatedAt) }
    }

    /**
     * Watches for a sibling being installed while this app's process is alive. A new app
     * has never been opened, so Android treats it as stopped and sends it nothing. Waking
     * it with FLAG_INCLUDE_STOPPED_PACKAGES lets it pull the accent and switch its
     * launcher icon before the user ever opens it. Best effort: it needs one running
     * sibling to see the install. Otherwise the new app syncs when it is first opened.
     */
    @SuppressLint("UnspecifiedRegisterReceiverFlag")
    fun watchInstalls(app: Application) {
        val filter = IntentFilter(Intent.ACTION_PACKAGE_ADDED).apply { addDataScheme("package") }
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.getBooleanExtra(Intent.EXTRA_REPLACING, false)) return
                val added = intent.data?.schemeSpecificPart ?: return
                if (added == context.packageName) return
                val pending = goAsync()
                val appContext = context.applicationContext
                Thread {
                    try {
                        wake(appContext, added)
                    } catch (_: Exception) {
                    } finally {
                        pending.finish()
                    }
                }.start()
            }
        }
        if (Build.VERSION.SDK_INT >= 33) {
            app.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            app.registerReceiver(receiver, filter)
        }
    }

    @Suppress("DEPRECATION")
    private fun wake(context: Context, added: String) {
        val pm = context.packageManager
        val isSibling = pm.queryIntentContentProviders(Intent(ACTION_PROVIDER), 0)
            .any { it.providerInfo?.packageName == added }
        if (!isSibling || !sameSigner(pm, context, added)) return
        context.sendBroadcast(
            Intent(ACTION_POKE)
                .setPackage(added)
                .addFlags(Intent.FLAG_INCLUDE_STOPPED_PACKAGES),
        )
    }

    // -- discovery --------------------------------------------------------------

    private fun peers(context: Context): List<String> {
        val pm = context.packageManager
        val found = try {
            @Suppress("DEPRECATION")
            pm.queryIntentContentProviders(Intent(ACTION_PROVIDER), 0)
        } catch (_: Exception) {
            return emptyList()
        }
        return found.mapNotNull { it.providerInfo }
            .filter { it.packageName != context.packageName && sameSigner(pm, context, it.packageName) }
            .mapNotNull { it.authority?.substringBefore(';') }
    }

    @Suppress("DEPRECATION")
    private fun sameSigner(pm: PackageManager, context: Context, other: String): Boolean {
        return pm.checkSignatures(context.packageName, other) == PackageManager.SIGNATURE_MATCH
    }

    private fun query(context: Context, authority: String): State? {
        val uri = Uri.parse("content://$authority/state")
        // Unstable: if the sibling's process dies mid-call, only the call fails, not this app.
        val client = context.contentResolver.acquireUnstableContentProviderClient(uri) ?: return null
        return try {
            client.query(uri, null, null, null, null)?.use { cursor ->
                if (!cursor.moveToFirst()) return@use null
                val accent = cursor.getString(0) ?: return@use null
                if (!valid(accent)) return@use null
                val mode = if (cursor.columnCount > 2) cursor.getString(2) else null
                State(accent, if (mode != null && validMode(mode)) mode else "", cursor.getLong(1))
            }
        } catch (_: Exception) {
            null
        } finally {
            client.release()
        }
    }

    private fun pokePeers(context: Context) {
        val pm = context.packageManager
        val found = try {
            @Suppress("DEPRECATION")
            pm.queryIntentContentProviders(Intent(ACTION_PROVIDER), 0)
        } catch (_: Exception) {
            return
        }
        for (info in found.mapNotNull { it.providerInfo }) {
            if (info.packageName == context.packageName) continue
            if (!sameSigner(pm, context, info.packageName)) continue
            context.sendBroadcast(Intent(ACTION_POKE).setPackage(info.packageName))
        }
    }

    // -- storage ----------------------------------------------------------------

    private fun valid(accent: String) = accent.isNotEmpty() && accent.all { it in 'a'..'z' }

    private fun validMode(mode: String) = mode == "system" || mode == "light" || mode == "dark"

    private fun read(context: Context): Stored? {
        return try {
            val json = JSONObject(File(context.filesDir, FILE).readText())
            val accent = json.getString("accent")
            if (!valid(accent)) return null
            val mode = json.optString("mode", "system")
            Stored(
                json.optBoolean("enabled", true),
                State(accent, if (validMode(mode)) mode else "system", json.optLong("updatedAt", 0)),
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun write(context: Context, stored: Stored) {
        val json = JSONObject()
            .put("enabled", stored.enabled)
            .put("accent", stored.state.accent)
            .put("mode", stored.state.mode)
            .put("updatedAt", stored.state.updatedAt)
        val target = File(context.filesDir, FILE)
        val temp = File(context.filesDir, "$FILE.tmp")
        temp.writeText(json.toString())
        temp.renameTo(target)
    }

    internal fun readForProvider(context: Context): Pair<Boolean, State>? {
        return read(context)?.let { it.enabled to it.state }
    }
}

/** Read-only. Serves the accent to siblings signed with the same key. */
class ThemeSyncProvider : ContentProvider() {
    override fun onCreate() = true

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?,
    ): Cursor {
        val cursor = MatrixCursor(arrayOf("accent", "updated_at", "mode"))
        val context = context ?: return cursor
        @Suppress("DEPRECATION")
        val trusted = context.packageManager
            .checkSignatures(Binder.getCallingUid(), Process.myUid()) == PackageManager.SIGNATURE_MATCH
        if (!trusted) return cursor
        val (enabled, state) = ThemeSync.readForProvider(context) ?: return cursor
        if (enabled) cursor.addRow(arrayOf<Any>(state.accent, state.updatedAt, state.mode))
        return cursor
    }

    override fun getType(uri: Uri): String? = null
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?) = 0
    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<out String>?,
    ) = 0
}

/**
 * A sibling changed its accent. This only says "look again": the value itself is
 * pulled from the provider, where the signature is checked, so a forged broadcast
 * can do nothing.
 */
class ThemeSyncReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ThemeSync.ACTION_POKE) return
        val pending = goAsync()
        val done = AtomicBoolean(false)
        val finish = { if (done.compareAndSet(false, true)) pending.finish() }
        val main = Handler(Looper.getMainLooper())
        main.postDelayed(finish, 8000)
        val app = context.applicationContext
        // Pull natively first: that is what changes the icon, and it works even when
        // the Dart side has not started yet. Then let Dart refresh its own settings.
        Thread {
            try {
                ThemeSync.pull(app)
            } catch (_: Exception) {
            }
            main.post { EngineHolder.requestThemeSync(app, finish) }
        }.start()
    }
}
