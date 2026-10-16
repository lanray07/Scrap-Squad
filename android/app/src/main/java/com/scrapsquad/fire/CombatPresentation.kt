package com.scrapsquad.fire

import org.json.JSONArray
import org.json.JSONObject

/** SpriteKit actions outlive the short simulation effect. Keep the same bounded
 * presentation lifetimes without changing the Swift simulation or hit timing. */
internal class CombatPresentation {
    data class Effect(val data: JSONObject, val born: Double, val duration: Double)
    private val active = linkedMapOf<Int, Effect>()
    private val seen = mutableSetOf<Int>()
    val effects get() = active.values
    fun update(elapsed: Double, source: JSONArray) {
        active.entries.removeAll { elapsed - it.value.born >= it.value.duration }
        val sourceIDs = source.objects().map { it.getInt("id") }.toSet()
        seen.retainAll(sourceIDs)
        source.objects().forEach { effect ->
            val id = effect.getInt("id")
            if (seen.add(id) && id !in active && active.size < 350) active[id] = Effect(effect, elapsed, if (effect.getDouble("damage") > 0) .45 else effect.getDouble("remaining"))
        }
    }
}
