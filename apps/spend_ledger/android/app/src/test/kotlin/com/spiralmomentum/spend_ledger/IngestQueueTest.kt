package com.spiralmomentum.spend_ledger

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class IngestQueueTest {
    @Test
    fun queuesUntilReadyThenDeliversInOrder() {
        val delivered = mutableListOf<Int>()
        val q = IngestQueue<Int> { delivered.add(it) }
        q.submit(1)
        q.submit(2)
        q.submit(3)
        assertEquals(emptyList<Int>(), delivered)
        assertFalse(q.isReady)

        q.markReady()
        assertEquals(listOf(1, 2, 3), delivered)
        assertTrue(q.isReady)

        q.submit(4)
        assertEquals(listOf(1, 2, 3, 4), delivered)
    }

    @Test
    fun resetQueuesAgain() {
        val delivered = mutableListOf<Int>()
        val q = IngestQueue<Int> { delivered.add(it) }
        q.markReady()
        q.submit(1)
        q.reset()
        q.submit(2)
        assertEquals(listOf(1), delivered)
        q.markReady()
        assertEquals(listOf(1, 2), delivered)
    }

    @Test
    fun resetReturnsPendingItems() {
        val q = IngestQueue<Int> { }
        q.submit(1)
        q.submit(2)
        assertEquals(listOf(1, 2), q.reset())
        q.markReady()
        assertEquals(emptyList<Int>(), q.reset())
    }

    @Test
    fun markReadyTwiceDoesNotRedeliver() {
        val delivered = mutableListOf<Int>()
        val q = IngestQueue<Int> { delivered.add(it) }
        q.submit(1)
        q.markReady()
        q.markReady()
        assertEquals(listOf(1), delivered)
    }
}
