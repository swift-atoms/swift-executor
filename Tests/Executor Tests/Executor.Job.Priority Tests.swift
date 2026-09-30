#if Clock

    import Clock
    import Executor
    import Executor_Job_Priority
    import Executor_Test_Support
    import Testing

    extension Executor.Job.Priority {
        @Suite
        struct Test {

            @Test
            func `empty priority queue reports isEmpty`() {
                let pq = Executor.Job.Priority()
                let empty = pq.isEmpty
                #expect(empty)
            }

            @Test
            func `peek on empty returns nil`() {
                let pq = Executor.Job.Priority()
                let deadline = pq.peek
                #expect(deadline == nil)
            }

            @Test
            func `pop on empty returns nil`() {
                var pq = Executor.Job.Priority()
                let now = Clock.Continuous.Instant(offset: .zero)
                let result = pq.pop(now: now)
                #expect(result == nil)
            }

            @Test
            func `same-deadline jobs drain in FIFO insertion order`() {
                var pq = Executor.Job.Priority()
                let deadline = Clock.Continuous.Instant(offset: .zero)

                (0..<5).forEach { tag in
                    pq.schedule(unsafe UnownedJob.mock(tag), at: deadline)
                }

                let fireTime = Clock.Continuous.Instant(offset: deadline.offset + .seconds(1))
                var observed: [Int] = []
                pq.drain(now: fireTime) { unsafe observed.append($0.tag) }

                #expect(observed == [0, 1, 2, 3, 4])
            }

            @Test
            func `earlier deadline fires before later deadline regardless of insertion order`() {
                var pq = Executor.Job.Priority()
                let now = Clock.Continuous.Instant(offset: .zero)
                let later = Clock.Continuous.Instant(offset: now.offset + .milliseconds(100))
                let earlier = Clock.Continuous.Instant(offset: now.offset + .milliseconds(10))

                pq.schedule(unsafe UnownedJob.mock(42), at: later)
                pq.schedule(unsafe UnownedJob.mock(7), at: earlier)

                let fireTime = Clock.Continuous.Instant(offset: now.offset + .seconds(1))
                var observed: [Int] = []
                pq.drain(now: fireTime) { unsafe observed.append($0.tag) }

                #expect(observed == [7, 42])
            }

            @Test
            func `deadline dominates FIFO sequence across mixed insertions`() {
                var pq = Executor.Job.Priority()
                let now = Clock.Continuous.Instant(offset: .zero)
                let early = Clock.Continuous.Instant(offset: now.offset + .milliseconds(10))
                let mid = Clock.Continuous.Instant(offset: now.offset + .milliseconds(50))

                pq.schedule(unsafe UnownedJob.mock(100), at: mid)
                pq.schedule(unsafe UnownedJob.mock(0), at: early)
                pq.schedule(unsafe UnownedJob.mock(101), at: mid)
                pq.schedule(unsafe UnownedJob.mock(1), at: early)
                pq.schedule(unsafe UnownedJob.mock(2), at: early)

                let fireTime = Clock.Continuous.Instant(offset: now.offset + .seconds(1))
                var observed: [Int] = []
                pq.drain(now: fireTime) { unsafe observed.append($0.tag) }

                #expect(observed == [0, 1, 2, 100, 101])
            }
        }
    }

#endif
