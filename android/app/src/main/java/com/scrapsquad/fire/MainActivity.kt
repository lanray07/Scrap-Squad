package com.scrapsquad.fire

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.os.Bundle

class MainActivity : Activity() {
    private lateinit var repository: GameRepository
    private lateinit var strings: Strings
    private lateinit var screens: MenuScreens
    private lateinit var audio: MenuAudio
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        repository = GameRepository(this); strings = Strings(this)
        try {
            repository.initialize(); audio = MenuAudio(this) { repository.profile.getJSONObject("preferences") }; screens = MenuScreens(this, repository, strings)
            screens.page = savedInstanceState?.getString("page") ?: "city"
            screens.show()
            val flags = getSharedPreferences("interface", MODE_PRIVATE)
            if (repository.battleJournal.pending()) {
                AlertDialog.Builder(this).setTitle(strings.text("android.recovery.title")).setMessage(strings.text("android.recovery.detail"))
                    .setPositiveButton(strings.text("battle.resume")) { _, _ -> resumeBattle(false) }
                    .setNegativeButton(strings.text("battle.retreat")) { _, _ -> resumeBattle(true) }.setCancelable(false).show()
            } else if (!flags.getBoolean("welcomed", false)) {
                AlertDialog.Builder(this).setTitle(strings.text("tutorial.title")).setMessage(strings.text("tutorial.body"))
                    .setPositiveButton(strings.text("tutorial.start")) { _, _ -> flags.edit().putBoolean("welcomed", true).apply(); screens.offerOffline() }
                    .setCancelable(false).show()
            } else screens.offerOffline()
        } catch (e: Exception) {
            android.util.Log.e("ScrapUI", "Native menu initialization failed", e)
            AlertDialog.Builder(this).setTitle(strings.text("error.load")).setMessage(e.message)
                .setPositiveButton(strings.text("common.ok")) { _, _ -> finish() }.setCancelable(false).show()
        }
    }
    override fun onRestart() { super.onRestart(); if (::screens.isInitialized) { repository.initialize(); if (repository.battleJournal.pending()) { recreate(); return }; screens.show(); screens.offerOffline() } }
    override fun onSaveInstanceState(outState: Bundle) { if (::screens.isInitialized) outState.putString("page", screens.page); super.onSaveInstanceState(outState) }
    override fun onResume() { super.onResume(); if (::audio.isInitialized) audio.resume() }
    override fun onPause() {
        if (::audio.isInitialized) audio.stop()
        if (::repository.isInitialized && !repository.battleJournal.pending()) runCatching { repository.action("background") }.onFailure { android.util.Log.e("ScrapSave", "Background save failed", it) }
        super.onPause()
    }
    override fun onDestroy() { if (::audio.isInitialized) audio.stop(); super.onDestroy() }
    fun playCue(name: String) { if (::audio.isInitialized) audio.cue(name) }
    fun refreshAudio() { if (::audio.isInitialized) audio.refresh() }
    fun hapticsEnabled() = ::repository.isInitialized && repository.profile.optJSONObject("preferences")?.optBoolean("haptics") == true
    fun deploy(mode: String, zone: Int, challenge: String? = null) {
        startActivity(Intent(this, BattleActivity::class.java).putExtra("mode", mode).putExtra("zone", zone).apply { if (challenge != null) putExtra("challenge", challenge) })
    }
    private fun resumeBattle(retreat: Boolean) { startActivity(Intent(this, BattleActivity::class.java).putExtra("retreatRecovered", retreat)) }
}
