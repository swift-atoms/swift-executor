public import Buffer
public import Buffer_Ring_Primitive
public import Deque
public import Executor_Job
public import Index
public import Memory
public import Memory_Allocator
public import Memory_Allocator_Protocol
public import Storage

extension Executor.Job {

    public struct Queue: ~Copyable {
        @usableFromInline
        internal var _storage: Deque<Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<UnownedJob>>.Ring>

        @inlinable
        public init() {
            self._storage = Deque<Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<UnownedJob>>.Ring>()

            do {
                self._storage.reserve(try .init(64))
            } catch {
                preconditionFailure("A constant non-negative capacity is representable: \(error)")
            }
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
