package com.scrapsquad.fire

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.os.Bundle

class MainActivity : Activity() {
    private lateinit var repository: GameRepository
    private lateinit var strings: Strings
    private lateinit var screens: MenuScreens
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        repository = GameRepository(this); strings = Strings(this)
        try {
            repository.initialize(); screens = MenuScreens(this, repository, strings)
            screens.page = savedInstanceState?.getString("page") ?: "city"
            screens.show()
            val flags = getSharedPreferences("interface", MODE_PRIVATE)
            if (!flags.getBoolean("welcomed", false)) {
                AlertDialog.Builder(this).setTitle(strings.text("tutorial.title")).setMessage(strings.text("tutorial.body"))
                    .setPositiveButton(strings.text("tutorial.start")) { _, _ -> flags.edit().putBoolean("welcomed", true).apply(); screens.offerOffline() }
                    .setCancelable(false).show()
            } else screens.offerOffline()
        } catch (e: Exception) {
            AlertDialog.Builder(this).setTitle(strings.text("error.load")).setMessage(e.message)
                .setPositiveButton(strings.text("common.ok")) { _, _ -> finish() }.setCancelable(false).show()
        }
    }
    override fun onRestart() { super.onRestart(); if (::screens.isInitialized) { repository.initialize(); screens.show(); screens.offerOffline() } }
    override fun onSaveInstanceState(outState: Bundle) { if (::screens.isInitialized) outState.putString("page", screens.page); super.onSaveInstanceState(outState) }
    fun deploy(mode: String, zone: Int, challenge: String? = null) {
        startActivity(Intent(this, BattleActivity::class.java).putExtra("mode", mode).putExtra("zone", zone).apply { if (challenge != null) putExtra("challenge", challenge) })
    }
}
