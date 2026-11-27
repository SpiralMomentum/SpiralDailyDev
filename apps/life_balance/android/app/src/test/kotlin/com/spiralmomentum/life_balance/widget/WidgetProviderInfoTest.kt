package com.spiralmomentum.life_balance.widget

import java.io.File
import javax.xml.parsers.DocumentBuilderFactory
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** 위젯 선택기 미리보기(API 31+ previewLayout)가 정적 레이아웃을 가리키는지 확인한다. */
class WidgetProviderInfoTest {
    // gradle unit test 작업 디렉터리 = android/app
    private val res = File("src/main/res")
    private val ns = "http://schemas.android.com/apk/res/android"

    private fun previewLayoutOf(info: String): String {
        val factory = DocumentBuilderFactory.newInstance().apply { isNamespaceAware = true }
        val root = factory.newDocumentBuilder().parse(File(res, "xml/$info.xml")).documentElement
        return root.getAttributeNS(ns, "previewLayout")
    }

    private fun assertPreview(info: String, layout: String) {
        assertEquals("@layout/$layout", previewLayoutOf(info))
        val file = File(res, "layout/$layout.xml")
        assertTrue("$file must exist", file.exists())
        val text = file.readText()
        assertTrue("preview shows sample balance", text.contains("@string/widget_preview_value"))
    }

    @Test
    fun smallHasPreviewLayout() = assertPreview("small_balance_info", "widget_small_preview")

    @Test
    fun mediumHasPreviewLayout() = assertPreview("medium_balance_info", "widget_medium_preview")

    @Test
    fun previewStringsAreSampleValues() {
        val strings = File(res, "values/widget_strings.xml").readText()
        assertTrue(strings.contains("<string name=\"widget_preview_label\">인생잔고</string>"))
        assertTrue(strings.contains("<string name=\"widget_preview_value\">12,345일</string>"))
    }
}
