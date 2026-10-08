package com.scrapsquad.fire

import android.content.Intent
import android.os.SystemClock
import android.view.KeyEvent
import android.view.InputDevice
import android.view.MotionEvent
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import java.io.File
import java.io.FileInputStream

/** Genuine native-screen captures. The achievable midgame fixture lives only in
 * the instrumentation APK; it never ships in the game or grants paid ownership. */
class StoreScreenshotsTest {
    @androidx.test.filters.SdkSuppress(minSdkVersion = 29)
    @Test fun captureNativeStoreScreensWithoutChangingPlayerSave() {
        val test = InstrumentationRegistry.getInstrumentation()
        val context = test.targetContext
        val files = listOf("profile.json", "pending-battle.json", "pending-battle.ndjson", "settled-battle.json")
        val backup = files.associateWith { name -> File(context.filesDir, name).takeIf { it.exists() }?.readBytes() }
        val flags = context.getSharedPreferences("interface", 0)
        val welcomed = flags.getBoolean("welcomed", false)
        flags.edit().putBoolean("welcomed", true).commit()
        var activity: MainActivity? = null
        var liveBattle: BattleActivity? = null
        try {
            activity = test.startActivitySync(Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)) as MainActivity
            test.waitForIdleSync()
            val repository = GameRepository(context)
            files.filter { it != "profile.json" }.forEach { File(context.filesDir, it).delete() }
            val profile = JSONObject(NativeCore.call("init", "content" to repository.content.toString()).getString("profile"))
            val content = repository.content
            profile.put("scrap", 1800).put("credits", 1500).put("cores", 8).put("zone", 3)
                .put("unlockedRobots", JSONArray(content.getJSONArray("robots").objects().map { it.getString("id") }))
                .put("squad", JSONArray(listOf("bolt", "tank", "patch")))
                .put("buildingLevels", JSONObject().also { levels -> content.getJSONArray("buildings").objects().forEach { levels.put(it.getString("id"), 2) } })
                .put("robotLevels", JSONObject().also { levels -> content.getJSONArray("robots").objects().forEach { levels.put(it.getString("id"), 5) } })
                .put("weapons", JSONObject().also { values -> content.getJSONArray("weapons").objects().forEach { values.put(it.getString("id"), 1) } })
                .put("weaponLevels", JSONObject().also { values -> content.getJSONArray("weapons").objects().forEach { values.put(it.getString("id"), 3) } })
                .put("equippedWeapon", "flame").put("blueprints", JSONArray(content.getJSONArray("recipes").objects().take(7).map { it.getString("id") }))
            repository.update(NativeCore.call("init", "content" to content.toString(), "profile" to profile.toString()))
            NativeCore.call("deploy", "mode" to "survival", "zone" to 0, "seed" to "424242")
            repeat(700) {
                val battle = NativeCore.call("state").getJSONObject("battle")
                when (battle.getString("state")) {
                    "fighting" -> NativeCore.call("step", "dt" to .05, "x" to kotlin.math.cos(it * .02), "y" to kotlin.math.sin(it * .02))
                    "choosing" -> NativeCore.call("choose", "id" to battle.getJSONArray("choices").getString(0))
                }
            }
            NativeCore.call("retreat"); repository.action("claim")
            val strings = Strings(context).apply { language = "en" }
            StoreArtExporter.export(context)
            val screens = MenuScreens(activity, repository, strings)
            fun capture(name: String) {
                test.waitForIdleSync(); SystemClock.sleep(350)
                test.uiAutomation.executeShellCommand("screencap -p /sdcard/Download/scrap-squad-$name.png").use { descriptor -> FileInputStream(descriptor.fileDescriptor).use { it.readBytes() } }
                val result = test.uiAutomation.executeShellCommand("ls /sdcard/Download/scrap-squad-$name.png").use { descriptor -> FileInputStream(descriptor.fileDescriptor).use { it.readBytes().toString(Charsets.UTF_8) } }
                assertTrue("Capture missing: $name", result.trim().endsWith("scrap-squad-$name.png"))
            }
            listOf("01-city" to "city", "02-squad" to "squad", "03-workshop" to "workshop", "04-blueprints" to "blueprints", "05-battle-lobby" to "battle", "06-shop" to "shop", "08-journal" to "journal").forEach { (name, page) ->
                test.runOnMainSync { screens.page = page; screens.show() }; capture(name)
            }
            val catalog = JSONObject(context.assets.open("generated/StoreConfiguration.json").bufferedReader().use { it.readText() })
            test.runOnMainSync { screens.page = "shop"; screens.show(); screens.premiumPreview(catalog.getJSONArray("packs").objects().first { it.getString("id").endsWith(".ronin") }, catalog) }
            capture("07-ronin-preview")
            test.sendKeyDownUpSync(KeyEvent.KEYCODE_BACK); test.waitForIdleSync()
            val run = repository.profile.getJSONObject("journal").getJSONArray("recent").getJSONObject(0)
            val medals = repository.action("menu").getJSONObject("menu").getJSONObject("runMedals").getJSONArray(run.getString("id")).strings()
            test.runOnMainSync { RunCard.preview(activity, RunCard.render(context, run, content, strings, medals), strings) }
            capture("09-run-card")
            test.sendKeyDownUpSync(KeyEvent.KEYCODE_BACK)
            test.waitForIdleSync()
            val monitor = test.addMonitor(BattleActivity::class.java.name, null, false)
            test.runOnMainSync { activity.deploy("bossRush", 3) }
            liveBattle = monitor.waitForActivityWithTimeout(15000) as? BattleActivity
            test.removeMonitor(monitor)
            assertNotNull("Live boss battle did not open", liveBattle)
            val size = context.resources.displayMetrics
            val cx = size.widthPixels * .5f; val cy = size.heightPixels * .55f
            val started = SystemClock.uptimeMillis()
            fun input(action: Int, px: Float, py: Float) {
                val event = MotionEvent.obtain(started, SystemClock.uptimeMillis(), action, px, py, 0).apply { source = InputDevice.SOURCE_TOUCHSCREEN }
                test.uiAutomation.injectInputEvent(event, true); event.recycle()
            }
            fun find(node: AccessibilityNodeInfo?, text: String): AccessibilityNodeInfo? {
                if (node == null) return null
                if (node.text?.toString()?.equals(text, true) == true) return node
                for (i in 0 until node.childCount) find(node.getChild(i), text)?.let { return it }
                return null
            }
            SystemClock.sleep(1200)
            input(MotionEvent.ACTION_DOWN, cx, cy)
            var captured = false
            while (SystemClock.uptimeMillis() - started < 25000) {
                val elapsed = (SystemClock.uptimeMillis() - started) / 1000.0
                input(MotionEvent.ACTION_MOVE, cx + kotlin.math.cos(elapsed * 1.5).toFloat() * 100, cy - kotlin.math.sin(elapsed * 1.5).toFloat() * 100)
                val state = NativeCore.call("state").optJSONObject("battle")
                if (state?.getString("state") == "choosing") {
                    val id = state.getJSONArray("choices").getString(0)
                    val upgrade = content.getJSONArray("upgrades").objects().first { it.getString("id") == id }
                    // Dialog labels contain the title and description as one row.
                    find(test.uiAutomation.rootInActiveWindow, strings.text(upgrade.getString("nameKey")) + "\n" + strings.text(upgrade.getString("descriptionKey")))?.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                }
                if (!captured && state?.getString("state") == "fighting" && state.getDouble("elapsed") > 5 && state.getJSONArray("warnings").length() > 0) { capture("10-boss-battle"); captured = true }
                if (state?.getString("state") in listOf("victory", "defeated")) break
                SystemClock.sleep(350)
            }
            input(MotionEvent.ACTION_UP, cx, cy)
            if (!captured) capture("10-boss-battle")
            val state = NativeCore.call("state").getJSONObject("battle")
            if (state.getString("state") == "choosing") {
                val id = state.getJSONArray("choices").getString(0)
                val upgrade = content.getJSONArray("upgrades").objects().first { it.getString("id") == id }
                find(test.uiAutomation.rootInActiveWindow, strings.text(upgrade.getString("nameKey")) + "\n" + strings.text(upgrade.getString("descriptionKey")))?.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                SystemClock.sleep(350)
            }
            if (state.getString("state") in listOf("fighting", "choosing")) {
                find(test.uiAutomation.rootInActiveWindow, strings.text("battle.pause"))?.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                SystemClock.sleep(250)
                find(test.uiAutomation.rootInActiveWindow, strings.text("battle.retreat"))?.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            }
            val deadline = SystemClock.uptimeMillis() + 10000
            while (find(test.uiAutomation.rootInActiveWindow, strings.text("battle.return")) == null && SystemClock.uptimeMillis() < deadline) SystemClock.sleep(100)
            assertNotNull("Benchmark run was not settled", find(test.uiAutomation.rootInActiveWindow, strings.text("battle.return")))
            test.runOnMainSync { liveBattle?.finish() }; test.waitForIdleSync(); liveBattle = null
        } finally {
            liveBattle?.let { active -> test.runOnMainSync { active.finish() }; test.waitForIdleSync() }
            activity?.let { active -> test.runOnMainSync { active.finish() }; test.waitForIdleSync() }
            backup.forEach { (name, bytes) -> val file = File(context.filesDir, name); if (bytes == null) file.delete() else file.writeBytes(bytes) }
            flags.edit().putBoolean("welcomed", welcomed).commit()
        }
    }
}
