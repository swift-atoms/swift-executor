import Executor
import Synchronization
import Testing

enum `Executor.Shutdown.Flag Tests` {}

extension `Executor.Shutdown.Flag Tests` {
    @Suite
    struct Test {

        @Test
        func `initial state is not set`() {
            let flag = Executor.Shutdown.Flag()
            let value = flag.isSet
            #expect(!value)
        }

        @Test
        func `set transitions to true`() {
            let flag = Executor.Shutdown.Flag()
            flag.set()
            let value = flag.isSet
            #expect(value)
        }

        @Test
        func `multiple set calls are idempotent`() {
            let flag = Executor.Shutdown.Flag()
            flag.set()
            flag.set()
            let value = flag.isSet
            #expect(value)
        }

        final class Channel: Sendable {
            let payload = Atomic<Int>(0)
            let flag = Executor.Shutdown.Flag()
        }

        @Test
        func `seeing the flag set makes the setter's earlier writes visible`() async {
            for round in 1...1_000 {
                let channel = Channel()
                async let observed: Int = {
                    while !channel.flag.isSet { await Task.yield() }
                    return channel.payload.load(ordering: .relaxed)
                }()
                channel.payload.store(round, ordering: .relaxed)
                channel.flag.set()
                let value = await observed
                #expect(value == round)
            }
        }
    }
}
