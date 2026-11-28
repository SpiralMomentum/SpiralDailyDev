package com.spiralmomentum.spend_ledger

import org.json.JSONArray
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

class NativeStoresLogicTest {
    private fun entry(at: Long, dartMs: Int? = 12) = mapOf<String, Any?>(
        "at" to at,
        "path" to "listener",
        "engineMs" to 300,
        "dartMs" to dartMs,
        "totalMs" to 400,
        "result" to "stored",
    )

    @Test
    fun appendDiagnosticStartsFromNull() {
        val json = JSONArray(appendDiagnostic(null, entry(1L)))
        assertEquals(1, json.length())
        val o = json.getJSONObject(0)
        assertEquals(1L, o.getLong("at"))
        assertEquals("listener", o.getString("path"))
        assertEquals(300, o.getInt("engineMs"))
        assertEquals(12, o.getInt("dartMs"))
        assertEquals(400, o.getInt("totalMs"))
        assertEquals("stored", o.getString("result"))
    }

    @Test
    fun appendDiagnosticOmitsNullDartMs() {
        val o = JSONArray(appendDiagnostic(null, entry(1L, dartMs = null))).getJSONObject(0)
        assertFalse(o.has("dartMs") && !o.isNull("dartMs"))
    }

    @Test
    fun appendDiagnosticKeepsLatest20() {
        var json: String? = null
        for (i in 1..21) json = appendDiagnostic(json, entry(i.toLong()))
        val arr = JSONArray(json)
        assertEquals(20, arr.length())
        val ats = (0 until arr.length()).map { arr.getJSONObject(it).getLong("at") }.toSet()
        assertEquals((2L..21L).toSet(), ats)
    }

    @Test
    fun appendDiagnosticIgnoresCorruptExisting() {
        assertEquals(1, JSONArray(appendDiagnostic("not json", entry(1L))).length())
    }

    @Test
    fun pushRecentMovesDuplicateToFront() {
        assertEquals(listOf("b", "a", "c"), pushRecent(listOf("a", "b", "c"), "b"))
        assertEquals(listOf("d", "a"), pushRecent(listOf("a"), "d"))
    }

    @Test
    fun pushRecentKeeps20() {
        val existing = (1..20).map { "p$it" }
        val next = pushRecent(existing, "new")
        assertEquals(20, next.size)
        assertEquals("new", next.first())
        assertEquals("p19", next.last())
    }
}
