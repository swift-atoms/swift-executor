import Executor
import Synchronization
import Testing

enum `Executor.Hosted Tests` {}

extension `Executor.Hosted Tests` {
    final class Wakes: Sendable {
        let count = Mutex(0)
        let signal: AsyncStream<Void>
        let continuation: AsyncStream<Void>.Continuation

        init() {
            (signal, continuation) = AsyncStream<Void>.makeStream()
        }

        func record() {
            count.withLock { $0 += 1 }
            continuation.yield()
        }
    }

    actor Counter {
        let executor: Executor.Hosted
        var value = 0

        init(executor: Executor.Hosted) {
            self.executor = executor
        }

        nonisolated var unownedExecutor: UnownedSerialExecutor {
            unsafe executor.asUnownedSerialExecutor()
        }

        func increment() {
            value += 1
        }

        func incrementTwiceAcrossYield() async {
            value += 1
            await Task.yield()
            value += 1
        }
    }
}

extension `Executor.Hosted Tests` {
    @Suite
    struct Test {

        @Test
        func `a new executor is empty and a drain with nothing queued returns`() {
            let executor = Executor.Hosted {}
            #expect(executor.isEmpty)
            executor.drain()
            #expect(executor.isEmpty)
        }

        @Test
        func `an enqueued job asks for a turn and runs only when drained`() async {
            let wakes = Wakes()
            let ran = Mutex(false)
            let executor = Executor.Hosted { wakes.record() }
            let counter = Counter(executor: executor)

            let task = Task {
                await counter.increment()
                ran.withLock { $0 = true }
            }
            for await _ in wakes.signal { break }

            #expect(wakes.count.withLock { $0 } == 1)
            #expect(!executor.isEmpty)
            #expect(!ran.withLock { $0 })

            executor.drain()
            await task.value

            #expect(ran.withLock { $0 })
            #expect(executor.isEmpty)
        }

        @Test
        func `a job that arrives after a drain asks for another turn`() async {
            let wakes = Wakes()
            let executor = Executor.Hosted { wakes.record() }
            let counter = Counter(executor: executor)
            let finished = Mutex(false)

            let task = Task {
                await counter.incrementTwiceAcrossYield()
                finished.withLock { $0 = true }
            }
            var turns = wakes.signal.makeAsyncIterator()

            await turns.next()
            executor.drain()
            #expect(!finished.withLock { $0 })

            await turns.next()
            executor.drain()
            await task.value

            #expect(finished.withLock { $0 })
            #expect(wakes.count.withLock { $0 } == 2)
        }
    }
}
