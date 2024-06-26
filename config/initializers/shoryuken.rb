require "#{Rails.root}/app/jobs/middleware/job_metrics_service_metric_middleware"

# set up default exponential backoff parameters
ActiveJob::QueueAdapters::ShoryukenAdapter::JobWrapper
  .shoryuken_options(auto_visibility_timeout: true,
                     retry_intervals: [5.seconds, 5.minutes, rand(4..8).hours])

if Rails.application.config.sqs_endpoint
  # override the sqs_endpoint
  Shoryuken::Client.sqs.config[:endpoint] = URI(Rails.application.config.sqs_endpoint)
end

if Rails.application.config.sqs_create_queues
  # create the development queues
  Shoryuken::Client.sqs.create_queue(queue_name: ActiveJob::Base.queue_name_prefix + "_low_priority")
  Shoryuken::Client.sqs.create_queue(queue_name: ActiveJob::Base.queue_name_prefix + "_med_priority")
  Shoryuken::Client.sqs.create_queue(queue_name: ActiveJob::Base.queue_name_prefix + "_high_priority")
end

Shoryuken.configure_server do |config|
  Rails.logger = Shoryuken::Logging.logger
  Rails.logger.level = Logger::INFO

  # register all shoryuken middleware
  config.server_middleware do |chain|
    chain.add JobMetricsServiceMetricMiddleware
  end
end
