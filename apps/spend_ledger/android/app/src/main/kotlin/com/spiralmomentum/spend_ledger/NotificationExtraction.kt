package com.spiralmomentum.spend_ledger

/** MessagingStyle 알림의 메시지 한 건. */
data class MessageFields(val text: String?, val timestampMs: Long?, val sender: String?)

/** 알림에서 꺼낸 값. 안드로이드 클래스에 의존하지 않아 JVM 테스트로 확인한다. */
data class NotificationFields(
    val packageName: String,
    val isGroupSummary: Boolean,
    val isOngoing: Boolean,
    val title: String?,
    val text: String?,
    val bigText: String?,
    val messages: List<MessageFields>,
    val postTimeMs: Long,
)

/** Dart `ingest`로 넘길 한 건. */
data class ExtractedMessage(
    val packageName: String,
    val text: String,
    val sender: String?,
    val postedAtMs: Long,
)

/**
 * 알림에서 원문·보낸 사람·게시 시각을 고른다. 그룹 요약·진행 중 알림이면 null.
 * MessagingStyle이면 마지막 메시지(본문이 비면 null)를 쓰고, 아니면 bigText → text 순이다.
 */
fun extractMessage(f: NotificationFields): ExtractedMessage? {
    if (f.isGroupSummary || f.isOngoing) return null
    val last = f.messages.lastOrNull()
    if (last != null) {
        val text = last.text?.takeIf { it.isNotBlank() } ?: return null
        return ExtractedMessage(
            packageName = f.packageName,
            text = text,
            sender = last.sender ?: f.title,
            postedAtMs = last.timestampMs ?: f.postTimeMs,
        )
    }
    val text = f.bigText?.takeIf { it.isNotBlank() }
        ?: f.text?.takeIf { it.isNotBlank() }
        ?: return null
    return ExtractedMessage(f.packageName, text, f.title, f.postTimeMs)
}

/** 허용 목록에 있는 앱의 알림만 엔진으로 넘긴다. */
fun shouldHandle(packageName: String, allowed: Set<String>): Boolean = packageName in allowed
