package ir.psdkjoon.komak

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import java.io.File

object ShareService {
    data class Received(val text: String?, val files: List<String>)

    @Volatile
    private var pending: Received? = null

    fun shareText(context: Context, text: String, subject: String? = null): Boolean {
        val send = Intent(Intent.ACTION_SEND)
            .setType("text/plain")
            .putExtra(Intent.EXTRA_TEXT, text)
        if (subject != null) send.putExtra(Intent.EXTRA_SUBJECT, subject)
        return chooser(context, send)
    }

    fun shareFiles(context: Context, paths: List<String>, mime: String? = null): Boolean {
        val uris = ArrayList(paths.mapNotNull { FileService.uriFor(context, File(it)) })
        if (uris.isEmpty()) return false
        val type = mime ?: FileService.mimeOf(paths.first())
        val send = if (uris.size == 1) {
            Intent(Intent.ACTION_SEND).putExtra(Intent.EXTRA_STREAM, uris[0])
        } else {
            Intent(Intent.ACTION_SEND_MULTIPLE).putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
        }
        send.setType(type).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        return chooser(context, send)
    }

    private fun chooser(context: Context, send: Intent): Boolean {
        val chooser = Intent.createChooser(send, context.getString(R.string.share))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            context.startActivity(chooser)
            true
        } catch (_: Exception) {
            false
        }
    }

    fun handle(context: Context, intent: Intent?) {
        if (intent == null) return
        val action = intent.action
        if (action != Intent.ACTION_SEND && action != Intent.ACTION_SEND_MULTIPLE) return
        val text = intent.getStringExtra(Intent.EXTRA_TEXT)
        val uris = streams(intent)
        if (uris.isEmpty()) {
            pending = Received(text, emptyList())
            return
        }
        val app = context.applicationContext
        Thread {
            val files = uris.mapNotNull { FileService.copyToCache(app, it, "received") }
            pending = Received(text, files)
        }.start()
    }

    fun consume(): Received? {
        val received = pending
        pending = null
        return received
    }

    fun setReceiving(context: Context, enabled: Boolean) {
        context.packageManager.setComponentEnabledSetting(
            ComponentName(context, "ir.psdkjoon.komak.ShareTarget"),
            if (enabled) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            },
            PackageManager.DONT_KILL_APP,
        )
    }

    @Suppress("DEPRECATION")
    private fun streams(intent: Intent): List<Uri> {
        if (intent.action == Intent.ACTION_SEND_MULTIPLE) {
            val list = if (Build.VERSION.SDK_INT >= 33) {
                intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
            }
            return list ?: emptyList()
        }
        val single = if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
        }
        return listOfNotNull(single)
    }
}
