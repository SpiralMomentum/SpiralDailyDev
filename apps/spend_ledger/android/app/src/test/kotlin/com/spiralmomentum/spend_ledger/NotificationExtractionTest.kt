package com.spiralmomentum.spend_ledger

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class NotificationExtractionTest {
    private val pkg = "com.samsung.android.messaging"

    private fun fields(
        isGroupSummary: Boolean = false,
        isOngoing: Boolean = false,
        title: String? = "15881688",
        text: String? = null,
        bigText: String? = null,
        messages: List<MessageFields> = emptyList(),
        postTimeMs: Long = 1_000L,
    ) = NotificationFields(
        packageName = pkg,
        isGroupSummary = isGroupSummary,
        isOngoing = isOngoing,
        title = title,
        text = text,
        bigText = bigText,
        messages = messages,
        postTimeMs = postTimeMs,
    )

    @Test
    fun messagingStyleUsesLastMessage() {
        val f = fields(
            messages = listOf(
                MessageFields("첫 문자 1,000원", 500L, "A"),
                MessageFields("둘째 문자 6,500원", 900L, "B"),
            ),
        )
        assertEquals(ExtractedMessage(pkg, "둘째 문자 6,500원", "B", 900L), extractMessage(f))
    }

    @Test
    fun lastMessageWithoutSenderFallsBackToTitle() {
        val f = fields(messages = listOf(MessageFields("6,500원", 900L, null)))
        assertEquals("15881688", extractMessage(f)?.sender)
    }

    @Test
    fun lastMessageWithoutTimestampUsesPostTime() {
        val f = fields(messages = listOf(MessageFields("6,500원", null, "B")), postTimeMs = 1_234L)
        assertEquals(1_234L, extractMessage(f)?.postedAtMs)
    }

    @Test
    fun lastMessageBlankTextIsNull() {
        val f = fields(
            bigText = "big",
            messages = listOf(MessageFields("6,500원", 1L, "A"), MessageFields("  ", 2L, "B")),
        )
        assertNull(extractMessage(f))
    }

    @Test
    fun groupSummaryIsNull() {
        assertNull(extractMessage(fields(isGroupSummary = true, text = "6,500원")))
    }

    @Test
    fun ongoingIsNull() {
        assertNull(extractMessage(fields(isOngoing = true, text = "6,500원")))
    }

    @Test
    fun withoutMessagesPrefersBigText() {
        val f = fields(text = "짧은 6,500원", bigText = "긴 원문 6,500원 스타벅스", postTimeMs = 777L)
        assertEquals(ExtractedMessage(pkg, "긴 원문 6,500원 스타벅스", "15881688", 777L), extractMessage(f))
    }

    @Test
    fun withoutBigTextUsesText() {
        val f = fields(text = "짧은 6,500원", bigText = null)
        assertEquals("짧은 6,500원", extractMessage(f)?.text)
    }

    @Test
    fun blankBigTextFallsBackToText() {
        val f = fields(text = "짧은 6,500원", bigText = "   ")
        assertEquals("짧은 6,500원", extractMessage(f)?.text)
    }

    @Test
    fun blankOnlyIsNull() {
        assertNull(extractMessage(fields(text = " \n ", bigText = "")))
        assertNull(extractMessage(fields(text = null, bigText = null)))
    }

    @Test
    fun shouldHandleChecksAllowList() {
        val allowed = setOf(pkg, "com.google.android.apps.messaging")
        assertTrue(shouldHandle(pkg, allowed))
        assertFalse(shouldHandle("com.kakao.talk", allowed))
        assertFalse(shouldHandle(pkg, emptySet()))
    }
}
