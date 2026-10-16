package com.scrapsquad.fire

import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Test

class CosmeticIconsTest {
    @Test fun exportAuthorizedCosmeticArtwork() {
        val test = InstrumentationRegistry.getInstrumentation()
        test.runOnMainSync { StoreArtExporter.export(test.targetContext) }
    }
}
