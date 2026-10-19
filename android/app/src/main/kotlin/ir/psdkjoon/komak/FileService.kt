package ir.psdkjoon.komak

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import android.widget.Toast
import androidx.core.content.FileProvider
import java.io.File

object FileService {
    private const val REQUEST_PICK = 4101
    private const val FILE_PROVIDER_SUFFIX = ".updates"
    private val folders = listOf("picked", "received")

    private var pickCallback: ((List<String>) -> Unit)? = null

    fun uriFor(context: Context, file: File): Uri? =
        try {
            FileProvider.getUriForFile(context, context.packageName + FILE_PROVIDER_SUFFIX, file)
        } catch (_: IllegalArgumentException) {
            null
        }

    fun mimeOf(name: String): String {
        val extension = name.substringAfterLast('.', "").lowercase()
        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
            ?: "application/octet-stream"
    }

    fun saveToDownloads(
        context: Context,
        source: File,
        name: String = source.name,
        mime: String? = null,
        toast: Boolean = true,
    ): Uri? {
        val type = mime ?: mimeOf(name)
        val saved = try {
            if (Build.VERSION.SDK_INT >= 29) {
                saveModern(context, source, name, type)
            } else {
                saveLegacy(source, name)
            }
        } catch (_: Exception) {
            null
        }
        if (saved != null && toast) {
            val app = context.applicationContext
            Handler(Looper.getMainLooper()).post {
                Toast.makeText(app, app.getString(R.string.saved_to_downloads), Toast.LENGTH_SHORT).show()
            }
        }
        return saved
    }

    fun saveToDownloads(
        context: Context,
        bytes: ByteArray,
        name: String,
        mime: String? = null,
        toast: Boolean = true,
    ): Uri? {
        val temp = File(context.cacheDir, "save_${System.nanoTime()}")
        return try {
            temp.writeBytes(bytes)
            saveToDownloads(context, temp, name, mime, toast)
        } finally {
            temp.delete()
        }
    }

    private fun saveModern(context: Context, source: File, name: String, type: String): Uri? {
        val resolver = context.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, type)
            put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values) ?: return null
        val output = resolver.openOutputStream(uri)
        if (output == null) {
            resolver.delete(uri, null, null)
            return null
        }
        output.use { out -> source.inputStream().use { it.copyTo(out) } }
        values.clear()
        values.put(MediaStore.MediaColumns.IS_PENDING, 0)
        resolver.update(uri, values, null, null)
        return uri
    }

    @Suppress("DEPRECATION")
    private fun saveLegacy(source: File, name: String): Uri? {
        val directory = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        directory.mkdirs()
        var target = File(directory, name)
        var counter = 1
        val stem = name.substringBeforeLast('.')
        val extension = name.substringAfterLast('.', "")
        while (target.exists()) {
            val suffix = if (extension.isEmpty()) "" else ".$extension"
            target = File(directory, "$stem ($counter)$suffix")
            counter++
        }
        source.copyTo(target)
        return Uri.fromFile(target)
    }

    fun pickFile(
        activity: Activity?,
        mimeTypes: List<String> = listOf("*/*"),
        multiple: Boolean = false,
        callback: (List<String>) -> Unit,
    ): Boolean {
        if (activity == null) return false
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType(if (mimeTypes.size == 1) mimeTypes[0] else "*/*")
            .putExtra(Intent.EXTRA_ALLOW_MULTIPLE, multiple)
        if (mimeTypes.size > 1) intent.putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes.toTypedArray())
        pickCallback = callback
        return try {
            activity.startActivityForResult(intent, REQUEST_PICK)
            true
        } catch (_: ActivityNotFoundException) {
            pickCallback = null
            false
        }
    }

    fun onResult(context: Context, requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_PICK) return false
        val callback = pickCallback ?: return true
        pickCallback = null
        val uris = if (resultCode == Activity.RESULT_OK && data != null) picked(data) else emptyList()
        if (uris.isEmpty()) {
            callback(emptyList())
            return true
        }
        val app = context.applicationContext
        Thread {
            val files = uris.mapNotNull { copyToCache(app, it, "picked") }
            Handler(Looper.getMainLooper()).post { callback(files) }
        }.start()
        return true
    }

    private fun picked(data: Intent): List<Uri> {
        val clip = data.clipData
        if (clip != null) return List(clip.itemCount) { clip.getItemAt(it).uri }
        return listOfNotNull(data.data)
    }

    fun copyToCache(context: Context, uri: Uri, folder: String): String? {
        return try {
            val name = displayName(context, uri) ?: "file"
            val safe = name.replace('/', '_').replace('\\', '_')
            val directory = File(File(context.cacheDir, folder), System.nanoTime().toString())
            directory.mkdirs()
            val target = File(directory, safe)
            val input = context.contentResolver.openInputStream(uri) ?: return null
            input.use { source -> target.outputStream().use { source.copyTo(it) } }
            target.absolutePath
        } catch (_: Exception) {
            null
        }
    }

    fun clearTemporaryFiles(context: Context) {
        for (folder in folders) File(context.cacheDir, folder).deleteRecursively()
    }

    private fun displayName(context: Context, uri: Uri): String? {
        if (uri.scheme != "content") return uri.lastPathSegment
        return context.contentResolver
            .query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }
    }

    fun openFile(context: Context, path: String, mime: String? = null): Boolean {
        val file = File(path)
        if (!file.isFile) return false
        val uri = uriFor(context, file) ?: return false
        return openUri(context, uri, mime ?: mimeOf(file.name))
    }

    fun openUri(context: Context, uri: Uri, mime: String): Boolean {
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, mime)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            context.startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }
}
