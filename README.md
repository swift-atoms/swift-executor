# swift-executor

Use this package when you are building an executor yourself and need the job containers and signals it runs on: `Executor.Job.Queue` for a plain run queue, `Executor.Job.Deque` for per-worker work stealing, `Executor.Job.Priority` for jobs that must not run before a deadline, and `Executor.Shutdown.Flag` to tell workers to stop. To run work on a ready-made executor, use the sibling package swift-executors instead.

## Laws

- No container runs, retains or releases a job. A job still inside a container when the container is destroyed never runs.
- `Executor.Job.Queue` is first in, first out and grows without bound. `drain(into:)` swaps the two queues' contents: the destination receives the source's jobs, and the source receives whatever the destination held before.
- `Executor.Job.Deque` is a work-stealing deque with one owner. Only the owning thread may call `push` and `take`; any thread may call `steal`. `take` returns the most recently pushed job, `steal` the oldest. The capacity is fixed at creation and must be a power of two; `push` returns `false` when the deque is full and never grows it. `take` and `steal` return `nil` both when the deque is empty and when they lose a race for the last job. Under contention, every pushed job is returned exactly once by either `take` or `steal`. `count` and `isEmpty` are snapshots that may already be out of date when read.
- `Executor.Job.Priority` releases jobs in order of earliest deadline. Jobs with equal deadlines come out in the order they were scheduled. `pop(now:)` and `drain(now:_:)` return only jobs whose deadline is at or before `now`, and `drain` stops at the first job not yet due. `peek` is the earliest deadline, whether or not it is due.
- `Executor.Shutdown.Flag` is one-way: `set()` cannot be undone, and calling it again has no further effect. `isSet` is a relaxed load, so seeing `true` does not make the setter's earlier writes visible to the reader.
