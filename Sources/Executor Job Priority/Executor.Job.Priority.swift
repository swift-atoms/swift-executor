#if Clock
    public import Clock
    public import Executor_Job
    public import Heap
    public import Index
    public import Memory_Allocator_Protocol

    extension Executor.Job {

        public struct Priority: ~Copyable {
            @usableFromInline
            internal var _storage: Heap<Entry>

            @usableFromInline
            internal var _nextSequence: UInt64

            @inlinable
            public init() {
                self._storage = Heap()
                self._nextSequence = 0
            }
        }
    }

    extension Executor.Job.Priority {

        @inlinable
        public var count: Index<UnownedJob>.Count { _storage.count.retag(UnownedJob.self) }

        @inlinable
        public var isEmpty: Bool { _storage.isEmpty }

        @inlinable
        public mutating func schedule(_ job: UnownedJob, at deadline: Clock.Continuous.Instant) {
            let sequence = _nextSequence
            _nextSequence &+= 1
            _storage.push(Entry(job: job, deadline: deadline, sequence: sequence))
        }

        @inlinable
        public var peek: Clock.Continuous.Instant? {
            _storage.isEmpty ? nil : _storage.min.deadline
        }

        @inlinable
        public mutating func pop(now: Clock.Continuous.Instant) -> UnownedJob? {
            guard !_storage.isEmpty, _storage.min.deadline <= now else { return nil }
            return _storage.pop()?.job
        }

        @inlinable
        public mutating func drain(
            now: Clock.Continuous.Instant,
            _ body: (UnownedJob) -> Void
        ) {
            while !_storage.isEmpty, _storage.min.deadline <= now {
                guard let popped = _storage.pop() else { break }
                body(popped.job)
            }
        }
    }
#endif
