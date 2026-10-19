package ir.psdkjoon.komak

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.FlutterInjector

object SoundChannel {
    private var pool: SoundPool? = null

    fun register(engine: FlutterEngine, context: Context) {
        val app = context.applicationContext
        MethodChannel(engine.dartExecutor.binaryMessenger, "komak/sound")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "load" -> {
                        val asset = call.argument<String>("asset")
                        if (asset == null) {
                            result.error("bad_asset", "No asset.", null)
                        } else {
                            result.success(load(app, asset))
                        }
                    }
                    "play" -> {
                        val id = call.argument<Int>("id") ?: 0
                        val volume = (call.argument<Double>("volume") ?: 0.6).toFloat()
                        if (id > 0) pool?.play(id, volume, volume, 1, 0, 1f)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun ensurePool(): SoundPool {
        pool?.let { return it }
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_GAME)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val created = SoundPool.Builder()
            .setMaxStreams(4)
            .setAudioAttributes(attributes)
            .build()
        pool = created
        return created
    }

    private fun load(context: Context, asset: String): Int {
        return try {
            val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(asset)
            context.assets.openFd(key).use { ensurePool().load(it, 1) }
        } catch (_: Exception) {
            0
        }
    }
}
