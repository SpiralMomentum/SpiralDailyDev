package com.spiralmomentum.life_balance.widget

import java.time.LocalDate
import java.time.temporal.ChronoUnit

/** 만기일 일정의 한 항목. Dart `ScheduleEntry`와 같다. */
data class Entry(val validFrom: LocalDate, val maturity: LocalDate)

/** Dart `Balance`와 같은 값. */
data class Balance(val remainingDays: Long, val bonusDays: Long, val totalDays: Long) {
    val isBonus: Boolean get() = bonusDays > 0 || remainingDays == 0L
}

/**
 * Dart domain 규칙(balance_calculator / balance_format / maturity_schedule / tone_table)의
 * Kotlin 사본. 두 구현은 test_vectors/balance_vectors.json 으로 함께 검증한다.
 */
object BalanceCalc {
    /** validFrom <= today 인 마지막 항목. 없으면 첫 항목. 소진되면 마지막 항목이 그대로 남는다. */
    fun entryFor(schedule: List<Entry>, today: LocalDate): Entry {
        var result = schedule.first()
        for (e in schedule) {
            if (!e.validFrom.isAfter(today)) result = e
        }
        return result
    }

    fun compute(birth: LocalDate, maturity: LocalDate, today: LocalDate): Balance {
        val left = ChronoUnit.DAYS.between(today, maturity)
        return Balance(
            remainingDays = if (left > 0) left else 0,
            bonusDays = if (left < 0) -left else 0,
            totalDays = ChronoUnit.DAYS.between(birth, maturity),
        )
    }

    fun format(b: Balance, unit: String): String {
        val bonus = b.isBonus
        val days = if (bonus) b.bonusDays else b.remainingDays
        val prefix = if (bonus) "+" else ""
        return when (unit) {
            "weeks" -> "$prefix${grouped(days / 7)}주"
            // 0.1년 단위: days * 10 / 365.2425 = days * 100000 / 3652425 (내림)
            "years" -> "$prefix${tenths(days * 100000 / 3652425)}년"
            "percent" -> {
                if (bonus) {
                    "+${grouped(days)}일"
                } else {
                    val permille = if (b.totalDays > 0) days * 1000 / b.totalDays else 0
                    "${tenths(permille)}%"
                }
            }
            else -> "$prefix${grouped(days)}일"
        }
    }

    fun usedRatio(b: Balance): Double {
        if (b.isBonus || b.totalDays <= 0) return 1.0
        return (1 - b.remainingDays.toDouble() / b.totalDays.toDouble()).coerceIn(0.0, 1.0)
    }

    /** variants[epochDay % n]. 비어 있으면 빈 문자열. */
    fun pick(variants: List<String>, today: LocalDate): String {
        if (variants.isEmpty()) return ""
        return variants[Math.floorMod(today.toEpochDay(), variants.size.toLong()).toInt()]
    }

    private fun grouped(n: Long): String {
        val s = n.toString()
        val sb = StringBuilder()
        for (i in s.indices) {
            if (i > 0 && (s.length - i) % 3 == 0) sb.append(',')
            sb.append(s[i])
        }
        return sb.toString()
    }

    private fun tenths(t: Long): String = "${t / 10}.${t % 10}"
}
