package com.spiralmomentum.spend_ledger

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WidgetColorsTest {
    /** 남색 테마(설계 4절) 값으로 12개 색 키를 채운다. */
    private fun fullData(): Map<String, String?> = mapOf(
        "color.widgetBackground.light" to "#FFFFFFFF",
        "color.widgetBackground.dark" to "#FF181D29",
        "color.onSurface.light" to "#FF171B24",
        "color.onSurface.dark" to "#FFE0E3EC",
        "color.subtle.light" to "#FF4C5468",
        "color.subtle.dark" to "#FFA3ABBE",
        "color.primary.light" to "#FF2F4A7A",
        "color.primary.dark" to "#FF9DB8F0",
        "color.track.light" to "#FFD6DEEE",
        "color.track.dark" to "#FF232B3D",
        "color.warning.light" to "#FFC2410C",
        "color.warning.dark" to "#FFFDBA74",
    )

    @Test
    fun parsesEightAndSixDigit() {
        assertEquals(0xFF2F4A7A.toInt(), parseArgb("#FF2F4A7A"))
        assertEquals(0xFF2F4A7A.toInt(), parseArgb("#2F4A7A"))
        assertEquals(0x802F4A7A.toInt(), parseArgb("#802f4a7a"))
        assertNull(parseArgb("2F4A7A"))
        assertNull(parseArgb("#GG0000"))
        assertNull(parseArgb("#2F4A7"))
        assertNull(parseArgb(""))
        assertNull(parseArgb(null))
    }

    @Test
    fun missingKeyGivesNull() {
        assertNull(widgetColors(fullData() - "color.track.dark"))
    }

    @Test
    fun badValueGivesNull() {
        assertNull(widgetColors(fullData() + ("color.primary.light" to "navy")))
    }

    @Test
    fun emptyDataGivesNull() {
        assertNull(widgetColors(emptyMap()))
    }

    @Test
    fun parsesPalettes() {
        val c = widgetColors(fullData())!!
        assertEquals(WidgetMode.SYSTEM, c.mode)
        assertEquals(
            WidgetPalette(
                widgetBackground = 0xFFFFFFFF.toInt(),
                onSurface = 0xFF171B24.toInt(),
                subtle = 0xFF4C5468.toInt(),
                primary = 0xFF2F4A7A.toInt(),
                track = 0xFFD6DEEE.toInt(),
                warning = 0xFFC2410C.toInt(),
            ),
            c.light,
        )
        assertEquals(0xFF181D29.toInt(), c.dark.widgetBackground)
        assertEquals(0xFFFDBA74.toInt(), c.dark.warning)
    }

    @Test
    fun modeAndPick() {
        val c = widgetColors(fullData() + ("theme.mode" to "dark"))!!
        assertEquals(WidgetMode.DARK, c.mode)
        assertEquals(c.dark, c.pick(nightNow = false))
        val l = widgetColors(fullData() + ("theme.mode" to "light"))!!
        assertEquals(WidgetMode.LIGHT, l.mode)
        assertEquals(l.light, l.pick(nightNow = true))
        val s = widgetColors(fullData() + ("theme.mode" to "weird"))!!
        assertEquals(WidgetMode.SYSTEM, s.mode)
        assertEquals(s.light, s.pick(nightNow = false))
        assertEquals(s.dark, s.pick(nightNow = true))
    }

    @Test
    fun keyNamesMatchDart() {
        // Dart widgetEntries가 쓰는 키(Global Constraints)와 Kotlin이 읽는 키가 같아야 한다.
        val expected = listOf(
            "color.widgetBackground.light", "color.widgetBackground.dark",
            "color.onSurface.light", "color.onSurface.dark",
            "color.subtle.light", "color.subtle.dark",
            "color.primary.light", "color.primary.dark",
            "color.track.light", "color.track.dark",
            "color.warning.light", "color.warning.dark",
        )
        assertEquals(expected.sorted(), WIDGET_COLOR_KEYS.sorted())
        assertEquals(12, WIDGET_COLOR_KEYS.toSet().size)
        assertEquals("theme.mode", WIDGET_MODE_KEY)
    }
}
