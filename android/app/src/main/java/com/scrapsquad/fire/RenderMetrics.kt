package com.scrapsquad.fire

import android.os.Build
import android.os.Debug
import com.badlogic.gdx.Gdx
import com.badlogic.gdx.graphics.GL20
import org.json.JSONObject

/** Bounded frame measurements. Emulator samples never imply Fire hardware FPS. */
internal class RenderMetrics {
    private val intervals = ArrayDeque<Double>()
    private val cpu = ArrayDeque<Double>()
    private var renderer = "unknown"
    fun record(delta: Double, cpuMillis: Double) {
        if (delta <= 0 || !delta.isFinite()) return
        if (renderer == "unknown") renderer = Gdx.gl.glGetString(GL20.GL_RENDERER) ?: "unknown"
        if (intervals.size >= 6000) { intervals.removeFirst(); cpu.removeFirst() }
        intervals.addLast(delta * 1000); cpu.addLast(cpuMillis)
    }
    fun report(): JSONObject {
        val sorted = intervals.sorted(); val duration = intervals.sum() / 1000
        val runtime = Runtime.getRuntime()
        val result = JSONObject().put("device", Build.MODEL).put("api", Build.VERSION.SDK_INT).put("abis", Build.SUPPORTED_ABIS.joinToString(","))
            .put("gpuRenderer", renderer).put("frames", sorted.size).put("sampleDurationSeconds", duration)
            .put("javaHeapBytes", runtime.totalMemory() - runtime.freeMemory()).put("nativeHeapBytes", Debug.getNativeHeapAllocatedSize())
            .put("scope", "Functional test sample; physical Fire tablet benchmarks required")
        if (sorted.isNotEmpty()) {
            fun percentile(fraction: Double) = sorted[((sorted.size - 1) * fraction).toInt()]
            result.put("averageRenderedFPS", sorted.size / duration).put("frameP50Ms", percentile(.5)).put("frameP95Ms", percentile(.95)).put("frameP99Ms", percentile(.99))
                .put("worstFrameMs", sorted.last()).put("averageRenderCpuMs", cpu.average()).put("framesOver33Ms", sorted.count { it > 33.333 })
        }
        return result
    }
}
