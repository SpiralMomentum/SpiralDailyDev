package com.spiralmomentum.life_balance.widget

import java.io.File
import java.time.LocalDate
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class OngoingNotificationTest {
    // gradle unit test 작업 디렉터리 = android/app. Dart notification_vectors_test.dart와 같은 파일.
    private val vectors = JSONArray(File("../../test_vectors/notification_vectors.json").readText())

    private val palette = Palette(0, 0, 0)

    private fun dataOf(v: JSONObject, phrases: Map<String, List<String>>): WidgetData {
        val s = v.getJSONArray("schedule")
        return WidgetData(
            schedule = (0 until s.length()).map {
                val e = s.getJSONObject(it)
                Entry(LocalDate.parse(e.getString("validFrom")), LocalDate.parse(e.getString("maturity")))
            },
            birth = LocalDate.parse(v.getString("birth")),
            unit = v.getString("unit"),
            tone = "wit",
            light = palette,
            dark = palette,
            phrases = phrases,
            notify = true,
        )
    }

    private fun phrasesOf(v: JSONObject): Map<String, List<String>> {
        val o = v.getJSONObject("phrases")
        return o.keys().asSequence().associateWith { k ->
            val arr = o.getJSONArray(k)
            (0 until arr.length()).map { arr.getString(it) }
        }
    }

    @Test
    fun matchesDartNotificationTextForSharedVectors() {
        assertTrue("vectors must not be empty", vectors.length() > 0)
        for (i in 0 until vectors.length()) {
            val v = vectors.getJSONObject(i)
            val text = notificationTextFor(dataOf(v, phrasesOf(v)), LocalDate.parse(v.getString("today")))
            assertEquals(v.getString("name"), v.getString("expected"), text)
        }
    }

    @Test
    fun missingPhraseGivesNull() {
        val v = vectors.getJSONObject(0)
        assertNull(notificationTextFor(dataOf(v, emptyMap()), LocalDate.parse(v.getString("today"))))
    }
}
