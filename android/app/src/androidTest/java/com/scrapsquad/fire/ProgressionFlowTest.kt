package com.scrapsquad.fire

import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

class ProgressionFlowTest {
    @Test fun fusionEquipmentUpgradeAndAtomicSaveSurviveReload() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val repository = GameRepository(context)
        // Isolate the progression fixture from the player's real/default save.
        val save = java.io.File(context.filesDir, "profile.json")
        val original = save.takeIf { it.exists() }?.readBytes()
        try {
            val fresh = NativeCore.call("init", "content" to repository.content.toString(), "now" to 1700000000)
            repository.update(fresh)
            val recipe = repository.content.getJSONArray("recipes").getJSONObject(0)
            val before = repository.profile.getInt("scrap")
            repository.action("fuse", "id" to recipe.getString("id"))
            assertEquals(before - recipe.getInt("scrapCost"), repository.profile.getInt("scrap"))
            val weapon = recipe.getString("result")
            repository.action("equip", "id" to weapon)
            val cost = repository.action("menu").getJSONObject("menu").getJSONObject("weaponCosts").getInt(weapon)
            val upgradeBefore = repository.profile.getInt("scrap")
            repository.action("weapon", "id" to weapon)
            assertEquals("Displayed upgrade price must equal actual debit", cost, upgradeBefore - repository.profile.getInt("scrap"))
            val expected = JSONObject(repository.profile.toString())
            val reopened = GameRepository(context); reopened.initialize()
            assertEquals(weapon, reopened.profile.getString("equippedWeapon"))
            assertEquals(expected.getInt("scrap"), reopened.profile.getInt("scrap"))
            assertEquals(2, reopened.profile.getJSONObject("weaponLevels").getInt(weapon))
            assertTrue(recipe.getString("id") in reopened.profile.getJSONArray("blueprints").strings())
        } finally {
            if (original == null) save.delete() else save.writeBytes(original)
        }
    }
    @Test fun deviceLocaleFallsBackWithoutShowingRawKeys() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val strings = Strings(context)
        strings.language = "zz-XY"
        assertEquals("Scrap Squad", strings.text("app.name"))
        assertFalse(strings.text("battle.deploy").startsWith("battle."))
    }
}
