require "benchmark"

# see https://dropwizard.github.io/metrics/3.1.0/getting-started/ for abstractions on metric types
# :nocov:
class MetricsService
  # rubocop:disable Metrics/MethodLength
  # update
  @app = "eFolder" 
  def self.record(description, service: nil, name: "unknown")
    return_value = nil

    Rails.logger.info("STARTED #{description}")
    stopwatch = Benchmark.measure do
      return_value = yield
    end
    # update
    if service && Rails.env.production?
      latency = stopwatch.real
      CustomMetricsService.emit_gauge(
        metric_group: "service",
        metric_name: "request_latency",
        metric_value: latency,
        app_name: @app,
        attrs: {
          service: service,
          endpoint: name
        }
      )
    end

    Rails.logger.info("FINISHED #{description}: #{stopwatch}")
    return_value
  rescue StandardError
    increment_datadog_counter("request_error", service, name) if service

    Rails.logger.info("RESCUED #{description}")

    # Re-raise the same error. We don't want to interfere at all in normal error handling.
    # This is just to capture the metric.
    raise
  ensure
    increment_datadog_counter("request_attempt", service, name) if service
  end
  # rubocop:enable Metrics/MethodLength
  # update
  private_class_method def self.increment_datadog_counter(metric_name, service, endpoint_name)
    CustomMetricsService.increment_counter(
      metric_group: "service",
      metric_name: metric_name,
      app_name: @app,
      attrs: {
        service: service,
        endpoint: endpoint_name
      }
    )
  end
end
# :nocov:
