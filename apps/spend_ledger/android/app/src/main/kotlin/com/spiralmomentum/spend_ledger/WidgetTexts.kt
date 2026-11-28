package com.spiralmomentum.spend_ledger

/** 위젯에 그릴 문자열. Dart가 저장한 페이로드(빈 문자열은 없음·숨김)에서 만든다. */
data class WidgetTexts(
    val total: String,
    val ratio: String,
    val today: String,
    val daily: String,
    val elapsedPercent: Int,
    val ratioPercent: Int?,
    val top: List<String>,
    val recent: List<String>,
    val pending: Int,
    val asOf: String,
)

private const val HIDDEN = "•••"

fun widgetTexts(data: Map<String, String?>): WidgetTexts {
    fun v(key: String): String = data[key].orEmpty()
    fun money(key: String): String = v(key).ifEmpty { HIDDEN }
    val ratioPercent = v("ratio").toIntOrNull()
    return WidgetTexts(
        total = money("total"),
        ratio = if (v("ratio").isEmpty()) "예산 없음" else "${v("ratio")}%",
        today = money("today"),
        daily = if (ratioPercent == null) "-" else money("daily"),
        elapsedPercent = v("elapsed").toIntOrNull()?.coerceIn(0, 100) ?: 0,
        ratioPercent = ratioPercent,
        top = (1..3).map { v("top$it") }.filter { it.isNotEmpty() },
        recent = (1..3).map { v("recent$it") }.filter { it.isNotEmpty() },
        pending = v("pending").toIntOrNull() ?: 0,
        asOf = v("asOf"),
    )
}

/** 진행 막대(ClipDrawable) level. 백분율을 0..100으로 자른 뒤 0..10000으로 옮긴다. 없으면 0. */
fun barLevel(percent: Int?): Int = (percent ?: 0).coerceIn(0, 100) * 100
