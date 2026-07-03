package com.alnlabs.pulimekagame

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

class NativeSoundHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    private val soundPool: SoundPool = SoundPool.Builder()
        .setMaxStreams(3)
        .setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_GAME)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
        )
        .build()

    private val soundIds = mutableMapOf<String, Int>()
    private var volume = 1f

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setVolume" -> {
                volume = (call.arguments as? Double)?.toFloat() ?: 1f
                result.success(null)
            }
            "play" -> {
                val args = call.arguments as? Map<*, *>
                val asset = args?.get("asset") as? String
                if (asset == null) {
                    result.notImplemented()
                    return
                }
                (args["volume"] as? Double)?.toFloat()?.let { volume = it }
                play(asset)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun play(asset: String) {
        val cached = soundIds[asset]
        if (cached != null) {
            soundPool.play(cached, volume, volume, 1, 0, 1f)
            return
        }

        try {
            val assetPath = "flutter_assets/$asset"
            context.assets.openFd(assetPath).use { afd ->
                val id = soundPool.load(afd, 1)
                soundIds[asset] = id
                soundPool.setOnLoadCompleteListener { _, sampleId, status ->
                    if (status == 0 && sampleId == id) {
                        soundPool.play(id, volume, volume, 1, 0, 1f)
                    }
                }
            }
        } catch (_: IOException) {
            // Ignore missing assets.
        }
    }
}
