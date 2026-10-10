package com.scrapsquad.fire

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import org.json.JSONObject

/** Original WAV playback for native screens; battle audio remains on libGDX. */
class MenuAudio(private val context: Context, private val preferences: () -> JSONObject) {
    private var music: MediaPlayer? = null
    private val voices = ArrayDeque<MediaPlayer>()
    private fun volume(music: Boolean): Float {
        val p = preferences(); return (p.optDouble("masterVolume", .7) * p.optDouble(if (music) "musicVolume" else "sfxVolume", .7)).toFloat()
    }
    private fun create(name: String): MediaPlayer = MediaPlayer().apply {
        try {
            setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_GAME).setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build())
            context.assets.openFd("generated/Audio/$name.wav").use { setDataSource(it.fileDescriptor, it.startOffset, it.length) }
            prepare()
        } catch (e: Exception) { release(); throw e }
    }
    fun resume() {
        if (music != null || volume(true) <= 0) return
        runCatching { music = create("city").apply { isLooping = true; setVolume(volume(true), volume(true)); start() } }.onFailure { android.util.Log.w("ScrapAudio", "City audio could not start", it) }
    }
    fun cue(name: String) {
        if (volume(false) <= 0) return
        runCatching {
            while (voices.size >= 8) voices.removeFirst().release()
            val player = create(name); voices.addLast(player)
            player.setVolume(volume(false), volume(false)); player.setOnCompletionListener { voices.remove(it); it.release() }; player.start()
        }.onFailure { android.util.Log.w("ScrapAudio", "Audio cue could not start: $name", it) }
    }
    fun refresh() { stop(); resume() }
    fun stop() { music?.release(); music = null; voices.forEach { it.release() }; voices.clear() }
}
