internal import Executor_Job
internal import Executor_Job_Queue
public import Executor_Primitive
internal import Synchronization

extension Executor {

    /// An executor whose jobs wait until a host gives it a turn.
    ///
    /// A host is an event loop that must not be blocked, such as a browser page's. Enqueueing a job never runs it:
    /// the job is queued, and `wake` is called when the queue was empty, so the host can arrange a turn. On that
    /// turn the host calls ``drain()``, which runs every queued job, including jobs enqueued while it runs.
    ///
    /// It is open so that a program can subclass it to add conformances this package cannot declare, such as the
    /// standard library's main-executor protocol while that is not yet public. No member can be overridden.
    open class Hosted: SerialExecutor, TaskExecutor, @unchecked Sendable {
        private let state: Mutex<State>
        private let wake: @Sendable () -> Void

        public init(wake: @escaping @Sendable () -> Void) {
            self.state = Mutex(State())
            self.wake = wake
        }
    }
}

extension Executor.Hosted {

    public var isEmpty: Bool {
        state.withLock { $0.jobs.isEmpty }
    }

    public func enqueue(_ job: consuming ExecutorJob) {
        let unowned = UnownedJob(job)
        let request = state.withLock { state -> Bool in
            let request = state.jobs.isEmpty && !state.draining
            state.jobs.enqueue(unowned)
            return request
        }
        if request { wake() }
    }

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        unsafe UnownedSerialExecutor(ordinary: self)
    }

    public func asUnownedTaskExecutor() -> UnownedTaskExecutor {
        unsafe UnownedTaskExecutor(ordinary: self)
    }

    /// Runs every queued job, including jobs enqueued while it runs. A call made from inside a drain returns at
    /// once.
    public func drain() {
        let entered = state.withLock { state -> Bool in
            if state.draining { return false }
            state.draining = true
            return true
        }
        guard entered else { return }
        while let job = next() {
            unsafe job.runSynchronously(on: asUnownedSerialExecutor())
        }
    }

    private func next() -> UnownedJob? {
        state.withLock { state -> UnownedJob? in
            if let job = state.jobs.dequeue() { return job }
            state.draining = false
            return nil
        }
    }
}
