package com.spiralmomentum.life_balance.widget

import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WidgetDataTest {
    // Task 9 리포트의 예시 항목 형식
    private val entries = mapOf(
        "lb_schedule" to """[{"validFrom":"2026-05-01","maturity":"2076-04-30"},{"validFrom":"2027-05-01","maturity":"2077-04-30"}]""",
        "lb_birth" to "1990-05-01",
        "lb_unit" to "days",
        "lb_tone" to "stoic",
        "lb_colors_light" to """{"bg":4294373863,"fg":4281019179,"accent":4289760599}""",
        "lb_colors_dark" to """{"bg":4280163094,"fg":4293781206,"accent":4289760599}""",
        "lb_phrases" to """{"widget.small_label":["a","b"],"widget.medium_label":["m"],"widget.withdrawal":["오늘 -1일"],"widget.bonus_label":["보너스 잔고"]}""",
    )

    @Test
    fun parsesTask9Payload() {
        val d = parseWidgetData { entries[it] }!!
        assertEquals(2, d.schedule.size)
        assertEquals(LocalDate.of(1990, 5, 1), d.birth)
        assertEquals(4294373863L.toInt(), d.light.bg)
        assertEquals(listOf("a", "b"), d.phrases["widget.small_label"])
        assertEquals(true, d.isStoic)
    }

    @Test
    fun missingKeyGivesNull() {
        assertNull(parseWidgetData { if (it == "lb_birth") null else entries[it] })
    }

    @Test
    fun brokenJsonGivesNull() {
        assertNull(parseWidgetData { if (it == "lb_schedule") "not json" else entries[it] })
    }

    @Test
    fun emptyScheduleGivesNull() {
        assertNull(parseWidgetData { if (it == "lb_schedule") "[]" else entries[it] })
    }

    @Test
    fun presentRollsToNextEntryAfterBirthday() {
        val d = parseWidgetData { entries[it] }!!
        val before = presentWidget(d, LocalDate.of(2027, 4, 30))
        val after = presentWidget(d, LocalDate.of(2027, 5, 1))
        // 2027-04-30 -> 2076-04-30, 2027-05-01 -> 2077-04-30
        assertEquals("17,898일", before.value)
        assertEquals("18,262일", after.value)
        assertEquals("오늘 -1일", after.withdrawal)
    }

    @Test
    fun presentBonusUsesBonusLabelAndFullBar() {
        val d = parseWidgetData { entries[it] }!!
        val v = presentWidget(d, LocalDate.of(2080, 1, 1))
        assertEquals(true, v.isBonus)
        assertEquals("보너스 잔고", v.smallLabel)
        assertEquals("보너스 잔고", v.mediumLabel)
        assertEquals(1.0f, v.usedRatio)
        assertEquals('+', v.value.first())
    }
}
