class JobDataDogMetricMiddleware
  def call(_worker, _queue, _msg, body)
    job_class = body["job_class"]

    stopwatch = Benchmark.measure do
      yield
    end

    DataDogService.emit_gauge(
      metric_group: "job",
      metric_name: "elapsed_time",
      metric_value: stopwatch.real,
      app_name: "eFolder",
      attrs: {
        job: job_class
      }
    )
  end
end
