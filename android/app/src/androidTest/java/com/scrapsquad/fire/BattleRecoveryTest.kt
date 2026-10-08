package com.scrapsquad.fire

import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import java.io.File

class BattleRecoveryTest {
    @Test fun durableReplayAndInterruptedRewardSettlementAreIdempotent() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val names = listOf("profile.json", "pending-battle.json", "pending-battle.ndjson", "settled-battle.json")
        val originals = names.associateWith { name -> File(context.filesDir, name).takeIf { it.exists() }?.readBytes() }
        val repository = GameRepository(context)
        try {
            repository.battleJournal.clear()
            repository.update(NativeCore.call("init", "content" to repository.content.toString(), "now" to 1700000000))
            repository.beginBattle("mode" to "survival", "seed" to "18446744073709551610", "zone" to 0)
            repeat(100) { repository.battleCommand("step", "dt" to .05, "x" to .7, "y" to .2) }
            repository.battleCommand("dash", "x" to 1.0, "y" to 0.0)
            repeat(30) { repository.battleCommand("step", "dt" to .05, "x" to -.4, "y" to .6) }
            val before = NativeCore.call("state").getJSONObject("battle")
            repository.battleJournal.close()
            // Simulate process termination after a partially written final frame.
            File(context.filesDir, "pending-battle.ndjson").appendText("{\"op\":\"step\",")
            val reopened = GameRepository(context); reopened.initialize()
            val restored = reopened.restoreBattle().getJSONObject("battle")
            assertEquals(before.getDouble("elapsed"), restored.getDouble("elapsed"), 1e-9)
            assertEquals(before.getJSONArray("player").toString(), restored.getJSONArray("player").toString())
            assertEquals(before.getJSONArray("enemies").toString(), restored.getJSONArray("enemies").toString())
            assertEquals(before.getDouble("health"), restored.getDouble("health"), 1e-9)
            reopened.battleCommand("retreat")
            val reward = NativeCore.call("claim")
            // Simulate death after the durable settlement, before profile.json is
            // replaced. Initialization must finish that transaction exactly once.
            reopened.battleJournal.settle(reward.getString("profile"))
            val completed = JSONObject(reward.getString("profile")).getInt("completedRuns")
            val afterCrash = GameRepository(context); afterCrash.initialize()
            assertEquals(completed, afterCrash.profile.getInt("completedRuns"))
            assertFalse(afterCrash.battleJournal.pending())
            afterCrash.initialize()
            assertEquals(completed, afterCrash.profile.getInt("completedRuns"))
        } finally {
            repository.battleJournal.clear()
            names.forEach { name -> val file = File(context.filesDir, name); val old = originals[name]; if (old == null) file.delete() else file.writeBytes(old) }
        }
    }
}
