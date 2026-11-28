package com.spiralmomentum.spend_ledger

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WidgetTextsTest {
    @Test
    fun hiddenAmountsShowDots() {
        val t = widgetTexts(mapOf("total" to "", "today" to "", "daily" to ""))
        assertEquals("•••", t.total)
    }

    @Test
    fun emptyRatioMeansNoBudget() {
        val t = widgetTexts(mapOf("ratio" to ""))
        assertEquals("예산 없음", t.ratio)
        assertNull(t.ratioPercent)
    }

    @Test
    fun ratioFormatsPercent() {
        val t = widgetTexts(mapOf("ratio" to "42", "elapsed" to "90"))
        assertEquals("42%", t.ratio)
        assertEquals(42, t.ratioPercent)
        assertEquals(90, t.elapsedPercent)
    }

    @Test
    fun emptyTopAndRecentAreDropped() {
        val t = widgetTexts(
            mapOf("top1" to "마트", "top2" to "", "top3" to "카페", "recent2" to "김밥"),
        )
        assertEquals(listOf("마트", "카페"), t.top)
        assertEquals(listOf("김밥"), t.recent)
    }

    @Test
    fun badPendingIsZero() {
        assertEquals(0, widgetTexts(mapOf("pending" to "x")).pending)
        assertEquals(0, widgetTexts(emptyMap()).pending)
        assertEquals(3, widgetTexts(mapOf("pending" to "3")).pending)
    }

    @Test
    fun barLevelClampsAndScales() {
        assertEquals(0, barLevel(null))
        assertEquals(0, barLevel(-5))
        assertEquals(0, barLevel(0))
        assertEquals(4200, barLevel(42))
        assertEquals(10000, barLevel(100))
        assertEquals(10000, barLevel(250))
    }
}
