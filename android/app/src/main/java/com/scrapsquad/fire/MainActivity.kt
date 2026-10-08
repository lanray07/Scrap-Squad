package com.scrapsquad.fire

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.os.Bundle
import android.widget.ArrayAdapter
import android.widget.ScrollView
import android.widget.Spinner

class MainActivity : Activity() {
    private lateinit var repository: GameRepository
    private lateinit var strings: Strings
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        repository = GameRepository(this); strings = Strings(this)
        try { repository.initialize(); showLobby() }
        catch (e: Exception) { AlertDialog.Builder(this).setTitle(strings.text("error.load")).setMessage(e.message).setPositiveButton(strings.text("common.ok")) { _, _ -> finish() }.setCancelable(false).show() }
    }
    override fun onRestart() { super.onRestart(); repository.initialize(); showLobby() }
    private fun showLobby() {
        val panel = Ui.panel(this); Ui.fitInsets(panel)
        panel.addView(Ui.text(this, "SCRAP SQUAD", 30f, Ui.gold))
        panel.addView(Ui.text(this, strings.text("battle.title"), 24f))
        panel.addView(Ui.text(this, strings.text("battle.subtitle"), color = Ui.muted))
        val modes = listOf("campaign", "survival", "bossRush", "scrapRun", "fusionLab", "dailyAnomaly", "arena")
        val mode = Spinner(this).apply { adapter = ArrayAdapter(this@MainActivity, android.R.layout.simple_spinner_dropdown_item, modes.map { strings.text("mode.$it") }) }
        panel.addView(Ui.text(this, strings.text("battle.mode"))); panel.addView(mode)
        val biomes = repository.content.getJSONArray("biomes")
        val zones = (0..repository.profile.getInt("zone")).toList()
        val zone = Spinner(this).apply { adapter = ArrayAdapter(this@MainActivity, android.R.layout.simple_spinner_dropdown_item, zones.map { strings.text(biomes.getJSONObject(it).getString("nameKey")) }) }
        panel.addView(Ui.text(this, strings.text("battle.zone"))); panel.addView(zone)
        val weapon = repository.profile.getString("equippedWeapon")
        panel.addView(Ui.text(this, strings.text("battle.weapon") + ": " + strings.text("weapon.$weapon"), 18f, Ui.mint))
        panel.addView(Ui.button(this, strings.text("battle.deploy")) { startActivity(Intent(this, BattleActivity::class.java).putExtra("mode", modes[mode.selectedItemPosition]).putExtra("zone", zone.selectedItemPosition)) })
        panel.addView(Ui.text(this, strings.text("battle.move"), color = Ui.muted))
        panel.addView(Ui.text(this, strings.text("battle.excitement.note"), color = Ui.muted))
        panel.addView(Ui.text(this, strings.text("battle.survival.note"), color = Ui.muted))
        setContentView(ScrollView(this).apply { setBackgroundColor(Ui.ink); addView(panel) })
    }
}
