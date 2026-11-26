package com.spiralmomentum.life_balance.widget

import java.io.File
import java.time.LocalDate
import kotlin.math.roundToLong
import org.json.JSONArray
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class BalanceCalcTest {
    // gradle unit test 작업 디렉터리 = android/app
    private val vectors = JSONArray(File("../../test_vectors/balance_vectors.json").readText())

    @Test
    fun allSharedVectorsMatch() {
        assertTrue("vectors must not be empty", vectors.length() > 0)
        for (i in 0 until vectors.length()) {
            val v = vectors.getJSONObject(i)
            val name = v.getString("name")
            val scheduleJson = v.getJSONArray("schedule")
            val schedule = (0 until scheduleJson.length()).map {
                val e = scheduleJson.getJSONObject(it)
                Entry(LocalDate.parse(e.getString("validFrom")), LocalDate.parse(e.getString("maturity")))
            }
            val today = LocalDate.parse(v.getString("today"))
            val birth = LocalDate.parse(v.getString("birth"))
            val expected = v.getJSONObject("expected")

            val entry = BalanceCalc.entryFor(schedule, today)
            val b = BalanceCalc.compute(birth, entry.maturity, today)

            assertEquals("$name remainingDays", expected.getLong("remainingDays"), b.remainingDays)
            assertEquals("$name bonusDays", expected.getLong("bonusDays"), b.bonusDays)
            assertEquals("$name display", expected.getString("display"), BalanceCalc.format(b, v.getString("unit")))
            assertEquals(
                "$name usedRatioPermille",
                expected.getLong("usedRatioPermille"),
                (BalanceCalc.usedRatio(b) * 1000).roundToLong(),
            )
        }
    }

    @Test
    fun pickUsesEpochDayModulo() {
        val today = LocalDate.ofEpochDay(20000)
        val variants = listOf("a", "b", "c")
        assertEquals(variants[20000 % 3], BalanceCalc.pick(variants, today))
    }

    @Test
    fun pickEmptyReturnsEmptyString() {
        assertEquals("", BalanceCalc.pick(emptyList(), LocalDate.ofEpochDay(20000)))
    }

    @Test
    fun entryForBeforeFirstUsesFirstAndExhaustedUsesLast() {
        val s = listOf(
            Entry(LocalDate.of(2026, 1, 1), LocalDate.of(2080, 1, 1)),
            Entry(LocalDate.of(2027, 1, 1), LocalDate.of(2080, 1, 5)),
        )
        assertEquals(s[0], BalanceCalc.entryFor(s, LocalDate.of(2025, 6, 1)))
        assertEquals(s[1], BalanceCalc.entryFor(s, LocalDate.of(2040, 6, 1)))
    }

    @Test
    fun largeNumbersGroupWithComma() {
        val b = Balance(remainingDays = 1234567, bonusDays = 0, totalDays = 2000000)
        assertEquals("1,234,567일", BalanceCalc.format(b, "days"))
    }
}
