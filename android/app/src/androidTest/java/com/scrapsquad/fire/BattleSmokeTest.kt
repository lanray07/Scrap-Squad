package com.scrapsquad.fire

import android.content.Intent
import android.graphics.Bitmap
import android.os.SystemClock
import android.view.InputDevice
import android.view.MotionEvent
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Test
import java.io.File
import java.io.FileInputStream

class BattleSmokeTest {
    private fun find(node: AccessibilityNodeInfo?, text: String): AccessibilityNodeInfo? {
        if (node == null) return null
        if (node.text?.toString()?.equals(text, ignoreCase = true) == true) return node
        for (i in 0 until node.childCount) find(node.getChild(i), text)?.let { return it }
        return null
    }
    @Test fun deployAndMoveOriginalRobots() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        context.startActivity(Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK))
        val automation = instrumentation.uiAutomation
        val strings = Strings(context)
        val welcomeDeadline = SystemClock.uptimeMillis() + 15000
        while (find(automation.rootInActiveWindow, strings.text("nav.battle")) == null && SystemClock.uptimeMillis() < welcomeDeadline) {
            find(automation.rootInActiveWindow, strings.text("tutorial.start"))?.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            SystemClock.sleep(100)
        }
        find(automation.rootInActiveWindow, strings.text("nav.battle"))?.performAction(AccessibilityNodeInfo.ACTION_CLICK)
        SystemClock.sleep(250)
        val deploy = Strings(context).text("battle.deploy")
        val deadline = SystemClock.uptimeMillis() + 15000
        var button: AccessibilityNodeInfo? = null
        while (button == null && SystemClock.uptimeMillis() < deadline) { button = find(automation.rootInActiveWindow, deploy); SystemClock.sleep(100) }
        assertNotNull("Native battle lobby did not appear", button)
        assertTrue(button!!.performAction(AccessibilityNodeInfo.ACTION_CLICK))
        var initial = NativeCore.call("state").optJSONObject("battle")
        while (initial == null && SystemClock.uptimeMillis() < deadline) { SystemClock.sleep(100); initial = NativeCore.call("state").optJSONObject("battle") }
        assertNotNull("libGDX never created the original simulation", initial)
        SystemClock.sleep(1000)
        val metrics = context.resources.displayMetrics
        val x = metrics.widthPixels * .5f; val y = metrics.heightPixels * .55f
        val down = SystemClock.uptimeMillis()
        fun input(action: Int, px: Float, py: Float) {
            val event = MotionEvent.obtain(down, SystemClock.uptimeMillis(), action, px, py, 0).apply { source = InputDevice.SOURCE_TOUCHSCREEN }
            assertTrue(automation.injectInputEvent(event, true)); event.recycle()
        }
        input(MotionEvent.ACTION_DOWN, x, y)
        input(MotionEvent.ACTION_MOVE, x + 100, y - 50)
        SystemClock.sleep(1500)
        input(MotionEvent.ACTION_UP, x + 100, y - 50)
        val moved = NativeCore.call("state").getJSONObject("battle")
        assertTrue("Touch input did not advance battle", moved.getDouble("elapsed") > initial!!.getDouble("elapsed"))
        assertTrue("Robots did not move", moved.getJSONArray("player").getDouble(0) > initial!!.getJSONArray("player").getDouble(0) + .05)
        val screenshot = automation.takeScreenshot()
        assertNotNull("Android screenshot unavailable", screenshot)
        val output = File(context.getExternalFilesDir(null), "android-battle-smoke.png")
        output.outputStream().use { screenshot!!.compress(Bitmap.CompressFormat.PNG, 100, it) }
        screenshot!!.recycle()
        // Capture directly as shell into public storage: scoped storage prevents
        // shell cp from reading this application's external-files directory.
        automation.executeShellCommand("screencap -p /sdcard/Download/scrap-squad-battle.png").use { descriptor ->
            FileInputStream(descriptor.fileDescriptor).use { it.readBytes() }
        }
        val retained = automation.executeShellCommand("ls /sdcard/Download/scrap-squad-battle.png").use { descriptor ->
            FileInputStream(descriptor.fileDescriptor).use { it.readBytes().toString(Charsets.UTF_8) }
        }
        assertTrue("Screenshot evidence was not retained: $retained", retained.trim() == "/sdcard/Download/scrap-squad-battle.png")
        find(automation.rootInActiveWindow, strings.text("battle.pause"))!!.performAction(AccessibilityNodeInfo.ACTION_CLICK)
        SystemClock.sleep(200)
        find(automation.rootInActiveWindow, strings.text("battle.retreat"))!!.performAction(AccessibilityNodeInfo.ACTION_CLICK)
        val returnDeadline = SystemClock.uptimeMillis() + 10000
        var returnButton: AccessibilityNodeInfo? = null
        while (returnButton == null && SystemClock.uptimeMillis() < returnDeadline) { returnButton = find(automation.rootInActiveWindow, strings.text("battle.return")); SystemClock.sleep(100) }
        assertNotNull("Retreated run was not settled", returnButton)
        returnButton!!.performAction(AccessibilityNodeInfo.ACTION_CLICK)
        SystemClock.sleep(500)
    }
}
