package com.spiralmomentum.spend_ledger

/** 위젯 밝기. Dart `theme.mode` 값(system·light·dark)에 대응. */
enum class WidgetMode { SYSTEM, LIGHT, DARK }

/** 한 밝기의 위젯 색(ARGB). */
data class WidgetPalette(
    val widgetBackground: Int,
    val onSurface: Int,
    val subtle: Int,
    val primary: Int,
    val track: Int,
    val warning: Int,
)

data class WidgetColors(val mode: WidgetMode, val light: WidgetPalette, val dark: WidgetPalette)

const val WIDGET_MODE_KEY = "theme.mode"

private val TOKENS = listOf("widgetBackground", "onSurface", "subtle", "primary", "track", "warning")

private fun colorKey(token: String, dark: Boolean): String =
    "color.$token.${if (dark) "dark" else "light"}"

/** Dart `widgetEntries`가 쓰는 12개 색 키. [widgetColors]는 이 목록만 읽는다. */
val WIDGET_COLOR_KEYS: List<String> =
    TOKENS.flatMap { listOf(colorKey(it, dark = false), colorKey(it, dark = true)) }

private val HEX = Regex("^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$")

/** `#AARRGGBB` 또는 `#RRGGBB`(알파 FF)를 ARGB Int로. 그 외는 null. */
fun parseArgb(s: String?): Int? {
    if (s == null || !HEX.matches(s)) return null
    val v = s.substring(1).toLong(16)
    return (if (s.length == 7) v or 0xFF000000L else v).toInt()
}

/** 저장소 값에서 위젯 색을 만든다. 색 키 하나라도 없거나 깨졌으면 null(XML 기본색 유지). */
fun widgetColors(data: Map<String, String?>): WidgetColors? {
    val parsed = WIDGET_COLOR_KEYS.associateWith { parseArgb(data[it]) ?: return null }
    fun palette(dark: Boolean): WidgetPalette {
        fun c(token: String) = parsed.getValue(colorKey(token, dark))
        return WidgetPalette(
            widgetBackground = c("widgetBackground"),
            onSurface = c("onSurface"),
            subtle = c("subtle"),
            primary = c("primary"),
            track = c("track"),
            warning = c("warning"),
        )
    }
    val mode = when (data[WIDGET_MODE_KEY]) {
        "light" -> WidgetMode.LIGHT
        "dark" -> WidgetMode.DARK
        else -> WidgetMode.SYSTEM
    }
    return WidgetColors(mode, palette(dark = false), palette(dark = true))
}

/** 지금 칠할 한 벌. SYSTEM은 [nightNow]로 고른다. */
fun WidgetColors.pick(nightNow: Boolean): WidgetPalette = when (mode) {
    WidgetMode.LIGHT -> light
    WidgetMode.DARK -> dark
    WidgetMode.SYSTEM -> if (nightNow) dark else light
}
