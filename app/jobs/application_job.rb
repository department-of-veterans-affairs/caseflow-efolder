class ApplicationJob < ActiveJob::Base
  attr_accessor :start_time

  before_perform do |job|
    # setup debug context
    Raven.tags_context(job: job.class.name, queue: job.queue_name)

    job.start_time = Time.zone.now
  end

  def metrics_service_report_runtime(metric_group_name:)
    MetricsService.record_runtime(
      app_name: "efolder_job",
      metric_group: metric_group_name,
      start_time: start_time
    )
  end

  def metrics_service_report_time_segment(segment:, start_time:)
    job_duration_seconds = Time.zone.now - start_time

    MetricsService.emit_gauge(
      app_name: "efolder_job_segment",
      metric_group: segment,
      metric_name: "runtime",
      metric_value: job_duration_seconds
    )
  end
end
