import Executor
import Testing

enum `Executor.Job.Queue Tests` {}

extension `Executor.Job.Queue Tests` {
    @Suite
    struct Test {

        @Test
        func `empty queue reports isEmpty`() {
            let queue = Executor.Job.Queue()
            let empty = queue.isEmpty
            #expect(empty)
        }

        @Test
        func `dequeue from empty returns nil`() {
            var queue = Executor.Job.Queue()
            let result = queue.dequeue()
            #expect(result == nil)
        }

        @Test
        func `drain on empty queues is safe`() {
            var source = Executor.Job.Queue()
            var destination = Executor.Job.Queue()

            source.drain(into: &destination)

            let sourceEmpty = source.isEmpty
            let destEmpty = destination.isEmpty
            #expect(sourceEmpty)
            #expect(destEmpty)
        }
    }
}
