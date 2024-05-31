class JobDataDogMetricMiddleware
  def call(_worker, queue, _msg, body)
    job_class = body["job_class"]

    stopwatch = Benchmark.measure do
      yield
    end

    begin
      DataDogService.emit_gauge(
        metric_group: "job",
        metric_name: "elapsed_time",
        metric_value: stopwatch.real,
        app_name: "efolder",
        attrs: {
          job: job_class
        }
      )
    rescue StandardError => error
      tags = { job: job_class, queue: queue }
      context = { message: body }
      Raven.capture_exception(error, tags: tags, extra: context) unless error.ignorable?
    end
  end
end
