package com.scrapsquad.fire

import androidx.test.platform.app.InstrumentationRegistry
import android.content.Intent
import com.amazon.device.drm.LicensingService
import com.amazon.device.drm.model.LicenseResponse
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.Assume.assumeTrue
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/** Run only on a Fire device configured with the official Amazon App Tester. */
class AmazonSandboxConnectionTest {
    @Test fun officialTesterReturnsLicensedSandbox() {
        assumeTrue("Requires a physical Fire device and official App Tester", InstrumentationRegistry.getArguments().getString("fireSandbox") == "true")
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val latch = CountDownLatch(1)
        var status: LicenseResponse.RequestStatus? = null
        instrumentation.startActivitySync(Intent(instrumentation.targetContext, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        instrumentation.runOnMainSync {
            LicensingService.verifyLicense(instrumentation.targetContext) {
                status = it.requestStatus
                latch.countDown()
            }
        }
        assertEquals("SANDBOX", LicensingService.getAppstoreSDKMode())
        assertTrue("Amazon license callback timed out", latch.await(30, TimeUnit.SECONDS))
        assertEquals(LicenseResponse.RequestStatus.LICENSED, status)
    }
}
