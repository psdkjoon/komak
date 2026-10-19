package ir.psdkjoon.komak

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PersistableBundle
import android.widget.Toast

object ClipboardService {
    fun copy(
        context: Context,
        text: String,
        sensitive: Boolean = false,
        toast: Boolean = true,
    ): Boolean {
        val manager = context.getSystemService(ClipboardManager::class.java) ?: return false
        val clip = ClipData.newPlainText("text", text)
        if (sensitive && Build.VERSION.SDK_INT >= 33) {
            clip.description.extras = PersistableBundle().apply {
                putBoolean(ClipDescription.EXTRA_IS_SENSITIVE, true)
            }
        }
        return try {
            manager.setPrimaryClip(clip)
            if (toast && Build.VERSION.SDK_INT < 33) {
                val app = context.applicationContext
                Handler(Looper.getMainLooper()).post {
                    Toast.makeText(app, app.getString(R.string.copied), Toast.LENGTH_SHORT).show()
                }
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    fun read(context: Context): String? {
        val manager = context.getSystemService(ClipboardManager::class.java) ?: return null
        val clip = manager.primaryClip ?: return null
        if (clip.itemCount == 0) return null
        return clip.getItemAt(0).coerceToText(context)?.toString()
    }

    fun hasText(context: Context): Boolean {
        val manager = context.getSystemService(ClipboardManager::class.java) ?: return false
        return manager.hasPrimaryClip()
    }
}
