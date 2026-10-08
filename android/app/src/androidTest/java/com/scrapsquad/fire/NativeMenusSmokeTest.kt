package com.scrapsquad.fire

import android.content.Intent
import android.os.SystemClock
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

class NativeMenusSmokeTest {
    private val instrumentation get() = InstrumentationRegistry.getInstrumentation()
    private fun find(node: AccessibilityNodeInfo?, text: String): AccessibilityNodeInfo? {
        if (node == null) return null
        if (node.text?.toString() == text) return node
        for (i in 0 until node.childCount) find(node.getChild(i), text)?.let { return it }
        return null
    }
    private fun click(text: String) {
        val deadline = SystemClock.uptimeMillis() + 10000
        while (SystemClock.uptimeMillis() < deadline) {
            find(instrumentation.uiAutomation.rootInActiveWindow, text)?.let { assertTrue(it.performAction(AccessibilityNodeInfo.ACTION_CLICK)); SystemClock.sleep(250); return }
            SystemClock.sleep(100)
        }
        fail("Missing native control: $text")
    }
    @Test fun navigateOriginalMenusAndFuseAWeapon() {
        val context = instrumentation.targetContext; val strings = Strings(context)
        context.startActivity(Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK))
        SystemClock.sleep(1000)
        find(instrumentation.uiAutomation.rootInActiveWindow, strings.text("tutorial.start"))?.performAction(AccessibilityNodeInfo.ACTION_CLICK)
        click(strings.text("city.workshop"))
        val before = JSONObject(NativeCore.call("state").getString("profile"))
        click(strings.text("lab.fuse"))
        click(strings.text("lab.equip"))
        val after = JSONObject(NativeCore.call("state").getString("profile"))
        assertEquals("flame", after.getString("equippedWeapon"))
        assertTrue(after.getInt("scrap") < before.getInt("scrap"))
        listOf("city" to "city.title", "squad" to "squad.title", "blueprints" to "lab.database", "shop" to "shop.title", "battle" to "battle.title").forEach { (page, heading) ->
            click(strings.text("nav.$page"))
            assertNotNull("Menu failed to render: $page", find(instrumentation.uiAutomation.rootInActiveWindow, strings.text(heading)))
        }
        click(strings.text("settings.title"))
        assertNotNull(find(instrumentation.uiAutomation.rootInActiveWindow, strings.text("settings.haptics")))
    }
}
