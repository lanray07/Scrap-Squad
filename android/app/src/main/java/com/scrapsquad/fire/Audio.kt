package com.scrapsquad.fire

import com.badlogic.gdx.Gdx
import com.badlogic.gdx.audio.Music
import com.badlogic.gdx.audio.Sound
import org.json.JSONObject

class Audio(private val preferences: JSONObject) {
    private val cues = mutableMapOf<String, Sound>()
    private var music: Music? = null
    private var track = ""
    private var paused = false
    private fun volume(key: String) = (preferences.optDouble("masterVolume", .7) * preferences.optDouble(key, .5)).toFloat()
    fun music(name: String) {
        if (track == name) return
        music?.dispose(); track = name
        music = Gdx.audio.newMusic(Gdx.files.internal("generated/Audio/$name.wav")).apply { isLooping = true; volume = volume("musicVolume"); if (!paused) play() }
    }
    fun cue(name: String) { cues.getOrPut(name) { Gdx.audio.newSound(Gdx.files.internal("generated/Audio/$name.wav")) }.play(volume("sfxVolume")) }
    fun pause() { paused = true; music?.pause() }
    fun resume() { paused = false; music?.play() }
    fun dispose() { music?.dispose(); cues.values.forEach { it.dispose() } }
}
