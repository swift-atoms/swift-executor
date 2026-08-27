public import Buffer_Ring_Primitive
public import Column
public import Deque
public import Executor_Job
public import Index

extension Executor.Job {

    public struct Queue: ~Copyable {
        @usableFromInline
        internal var _storage: Deque<Column.Ring<UnownedJob>>

        @inlinable
        public init() {
            self._storage = Deque<Column.Ring<UnownedJob>>()

            self._storage.reserve(try! .init(64))
        }
    }
}

extension Executor.Job.Queue {

    @inlinable
    public var count: Index<UnownedJob>.Count { _storage.count }

    @inlinable
    public var isEmpty: Bool { _storage.isEmpty }

    @inlinable
    public mutating func enqueue(_ job: UnownedJob) {
        _storage.push(job, to: .back)
    }

    @inlinable
    public mutating func dequeue() -> UnownedJob? {
        _storage.take(from: .front)
    }

    @inlinable
    public mutating func drain(into other: inout Executor.Job.Queue) {
        swap(&self._storage, &other._storage)
    }
}
