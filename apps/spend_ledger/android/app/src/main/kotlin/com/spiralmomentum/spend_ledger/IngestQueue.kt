package com.spiralmomentum.spend_ledger

/**
 * 엔진이 준비되기 전에 온 항목을 쌓아 두었다가 준비되면 순서대로 [deliver]로 넘긴다.
 * 스레드 안전하지 않다. 호출하는 쪽이 한 스레드(메인)에서만 쓴다.
 */
class IngestQueue<T>(private val deliver: (T) -> Unit) {
    private val pending = ArrayDeque<T>()

    var isReady: Boolean = false
        private set

    fun submit(item: T) {
        if (isReady) deliver(item) else pending.addLast(item)
    }

    /** 준비 상태로 바꾸고 쌓인 항목을 순서대로 넘긴다. */
    fun markReady() {
        isReady = true
        while (pending.isNotEmpty()) deliver(pending.removeFirst())
    }

    /** 준비 상태를 풀고(엔진 재시작), 아직 넘기지 못한 항목을 꺼내 돌려준다. */
    fun reset(): List<T> {
        isReady = false
        val left = pending.toList()
        pending.clear()
        return left
    }
}
