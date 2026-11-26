package com.spiralmomentum.life_balance.widget

import java.time.LocalDateTime
import java.time.ZoneId
import java.time.ZonedDateTime
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class MidnightAlarmTest {
    private val seoul = ZoneId.of("Asia/Seoul")

    private fun at(zone: ZoneId, y: Int, mo: Int, d: Int, h: Int, mi: Int, s: Int = 0) =
        ZonedDateTime.of(LocalDateTime.of(y, mo, d, h, mi, s), zone)

    @Test
    fun justBeforeMidnight() {
        val now = at(seoul, 2026, 11, 25, 23, 59, 30)
        assertEquals(
            at(seoul, 2026, 11, 26, 0, 1).toInstant().toEpochMilli(),
            MidnightAlarm.nextTriggerMillis(now),
        )
    }

    @Test
    fun exactlyMidnightGoesToNextDay() {
        val now = at(seoul, 2026, 11, 25, 0, 0, 0)
        assertEquals(
            at(seoul, 2026, 11, 26, 0, 1).toInstant().toEpochMilli(),
            MidnightAlarm.nextTriggerMillis(now),
        )
    }

    @Test
    fun yearEnd() {
        val now = at(seoul, 2026, 12, 31, 12, 0)
        assertEquals(
            at(seoul, 2027, 1, 1, 0, 1).toInstant().toEpochMilli(),
            MidnightAlarm.nextTriggerMillis(now),
        )
    }

    @Test
    fun dstGapAtMidnightUsesFirstValidInstant() {
        // 상파울루 2018-11-04 00:00 -> 01:00 (자정이 존재하지 않음)
        val sp = ZoneId.of("America/Sao_Paulo")
        val now = at(sp, 2018, 11, 3, 22, 0)
        assertEquals(
            at(sp, 2018, 11, 4, 1, 1).toInstant().toEpochMilli(),
            MidnightAlarm.nextTriggerMillis(now),
        )
    }

    @Test
    fun alwaysInFuture() {
        for (h in 0..23) {
            val now = at(seoul, 2026, 3, 8, h, 0)
            assertTrue(MidnightAlarm.nextTriggerMillis(now) > now.toInstant().toEpochMilli())
        }
    }
}
