package com.spiralmomentum.life_balance.widget

import android.content.SharedPreferences
import java.time.LocalDate
import org.json.JSONArray
import org.json.JSONObject

/** Dart `WidgetKeys`와 같은 키. 계약이므로 이름을 바꾸지 않는다. */
object WidgetKeys {
    const val SCHEDULE = "lb_schedule"
    const val BIRTH = "lb_birth"
    const val UNIT = "lb_unit"
    const val TONE = "lb_tone"
    const val COLORS_LIGHT = "lb_colors_light"
    const val COLORS_DARK = "lb_colors_dark"
    const val PHRASES = "lb_phrases"

    const val SMALL_LABEL = "widget.small_label"
    const val MEDIUM_LABEL = "widget.medium_label"
    const val WITHDRAWAL = "widget.withdrawal"
    const val BONUS_LABEL = "widget.bonus_label"
}

/** ARGB 색 3종. */
data class Palette(val bg: Int, val fg: Int, val accent: Int)

data class WidgetData(
    val schedule: List<Entry>,
    val birth: LocalDate,
    val unit: String,
    val tone: String,
    val light: Palette,
    val dark: Palette,
    val phrases: Map<String, List<String>>,
) {
    val isStoic: Boolean get() = tone == "stoic"
}

/** 위젯이 그릴 값. 오늘 날짜 기준으로 매 렌더마다 새로 만든다. */
data class WidgetView(
    val value: String,
    val smallLabel: String,
    val mediumLabel: String,
    val withdrawal: String,
    val usedRatio: Float,
    val isBonus: Boolean,
)

fun presentWidget(data: WidgetData, today: LocalDate): WidgetView {
    val entry = BalanceCalc.entryFor(data.schedule, today)
    val b = BalanceCalc.compute(data.birth, entry.maturity, today)
    fun phrase(key: String) = BalanceCalc.pick(data.phrases[key].orEmpty(), today)
    val bonusLabel = phrase(WidgetKeys.BONUS_LABEL)
    return WidgetView(
        value = BalanceCalc.format(b, data.unit),
        smallLabel = if (b.isBonus) bonusLabel else phrase(WidgetKeys.SMALL_LABEL),
        mediumLabel = if (b.isBonus) bonusLabel else phrase(WidgetKeys.MEDIUM_LABEL),
        withdrawal = phrase(WidgetKeys.WITHDRAWAL),
        usedRatio = BalanceCalc.usedRatio(b).toFloat(),
        isBonus = b.isBonus,
    )
}

/** home_widget 저장소(SharedPreferences)에서 읽는다. 값이 없거나 깨졌으면 null. */
fun readWidgetData(prefs: SharedPreferences): WidgetData? =
    parseWidgetData { key -> prefs.getString(key, null) }

/** 키 → 문자열 조회 함수만 받는 순수 파서. */
fun parseWidgetData(get: (String) -> String?): WidgetData? {
    val raw = listOf(
        WidgetKeys.SCHEDULE, WidgetKeys.BIRTH, WidgetKeys.UNIT, WidgetKeys.TONE,
        WidgetKeys.COLORS_LIGHT, WidgetKeys.COLORS_DARK, WidgetKeys.PHRASES,
    ).associateWith(get)
    if (raw.values.any { it == null }) return null
    val v = raw.mapValues { it.value!! }
    return try {
        val schedule = parseSchedule(v.getValue(WidgetKeys.SCHEDULE))
        if (schedule.isEmpty()) return null
        WidgetData(
            schedule = schedule,
            birth = LocalDate.parse(v.getValue(WidgetKeys.BIRTH)),
            unit = v.getValue(WidgetKeys.UNIT),
            tone = v.getValue(WidgetKeys.TONE),
            light = parsePalette(v.getValue(WidgetKeys.COLORS_LIGHT)),
            dark = parsePalette(v.getValue(WidgetKeys.COLORS_DARK)),
            phrases = parsePhrases(v.getValue(WidgetKeys.PHRASES)),
        )
    } catch (e: Exception) {
        null
    }
}

private fun parseSchedule(json: String): List<Entry> {
    val arr = JSONArray(json)
    return (0 until arr.length()).map {
        val o = arr.getJSONObject(it)
        Entry(LocalDate.parse(o.getString("validFrom")), LocalDate.parse(o.getString("maturity")))
    }
}

// Dart toARGB32()는 부호 없는 32비트 정수라 Int 범위를 넘는다. Long으로 읽고 toInt.
private fun parsePalette(json: String): Palette {
    val o = JSONObject(json)
    return Palette(
        bg = o.getLong("bg").toInt(),
        fg = o.getLong("fg").toInt(),
        accent = o.getLong("accent").toInt(),
    )
}

private fun parsePhrases(json: String): Map<String, List<String>> {
    val o = JSONObject(json)
    return o.keys().asSequence().associateWith { k ->
        val arr = o.getJSONArray(k)
        (0 until arr.length()).map { arr.getString(it) }
    }
}
