package com.scrapsquad.fire

import android.app.Instrumentation
import android.content.Intent
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.os.SystemClock
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Test

/** A missing Amazon catalog must never produce an inert purchase control. */
class ShopInteractionTest {
    @Test fun unavailableCatalogOffersAnActionInsteadOfADeadBuyButton() {
        val test = InstrumentationRegistry.getInstrumentation()
        val context = test.targetContext
        val monitor = Instrumentation.ActivityMonitor(MainActivity::class.java.name, null, false)
        test.addMonitor(monitor)
        context.startActivity(Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK))
        val activity = monitor.waitForActivityWithTimeout(15000) as? MainActivity
        assertNotNull("Main activity did not start", activity)
        try {
            test.runOnMainSync {
                val repository = GameRepository(context).apply { initialize() }
                val screens = MenuScreens(activity!!, repository, Strings(context))
                screens.page = "shop"
                screens.show()
                fun buttons(view: View): List<Button> = (if (view is Button) listOf(view) else emptyList()) +
                    (if (view is ViewGroup) (0 until view.childCount).flatMap { buttons(view.getChildAt(it)) } else emptyList())
                val buy = buttons(screens.panel).filter { it.text == Strings(context).text("cosmetic.buy") || it.tag?.toString()?.startsWith("shop.purchase.") == true }
                assertEquals("Every unowned cosmetic must have an actionable control", 7, buy.size)
                buy.forEach { assertTrue("Purchase control silently ignores taps when Amazon catalog is unavailable", it.isEnabled && it.hasOnClickListeners()) }
                assertTrue("An unavailable pack must respond to a tap", buy.first().performClick())
            }
            fun find(node: AccessibilityNodeInfo?): AccessibilityNodeInfo? {
                if (node == null) return null
                if (node.text?.toString() == Strings(context).text("android.shop.retry")) return node
                return (0 until node.childCount).firstNotNullOfOrNull { find(node.getChild(it)) }
            }
            val deadline = SystemClock.uptimeMillis() + 3000
            while (find(test.uiAutomation.rootInActiveWindow) == null && SystemClock.uptimeMillis() < deadline) SystemClock.sleep(50)
            assertNotNull("Tap must show an immediate explanation with a retry action", find(test.uiAutomation.rootInActiveWindow))
        } finally {
            activity?.let { test.runOnMainSync { it.finish() } }
            test.removeMonitor(monitor)
        }
    }
}
