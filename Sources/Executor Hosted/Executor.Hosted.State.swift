internal import Executor_Job
internal import Executor_Job_Queue
internal import Executor_Primitive

extension Executor.Hosted {

    struct State: ~Copyable {
        var jobs: Executor.Job.Queue
        var draining: Bool

        init() {
            self.jobs = Executor.Job.Queue()
            self.draining = false
        }
    }
}
