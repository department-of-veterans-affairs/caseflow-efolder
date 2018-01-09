class JobPrometheusMetricMiddleware
  def call(_worker, msg, _queue)
    name = msg["args"][0]["job_class"]

    yield
  rescue StandardError
    PrometheusService.background_jobs_error_counter.increment(name: name)

    # reraise the same error. This lets Sidekiq's retry logic kick off
    # as normal, but we still capture the error
    raise
  ensure
    PrometheusService.background_jobs_attempt_counter.increment(name: name)

    # No need to actually push in test/development/demo
    PrometheusService.push_metrics! if Rails.env.production?
  end
end
