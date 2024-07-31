# frozen_string_literal: true

require "benchmark"
require "datadog/statsd"
require "statsd-instrument"

# see https://dropwizard.github.io/metrics/3.1.0/getting-started/ for abstractions on metric types
class MetricsService
  @statsd = Datadog::Statsd.new

  # :reek:LongParameterList
  def self.increment_counter(metric_group:, metric_name:, app_name:, attrs: {}, by: 1)
    tags = get_tags(app_name, attrs)
    stat_name = get_stat_name(metric_group, metric_name)
    @statsd.increment(stat_name, tags: tags, by: by)

    # Dynatrace statD implementation
    StatsD.increment(stat_name, tags: tags)
  end

  def self.record_runtime(metric_group:, app_name:, start_time: Time.zone.now)
    metric_name = "runtime"
    job_duration_seconds = Time.zone.now - start_time

    emit_gauge(
      app_name: app_name,
      metric_group: metric_group,
      metric_name: metric_name,
      metric_value: job_duration_seconds
    )
  end

  # :reek:LongParameterList
  def self.emit_gauge(metric_group:, metric_name:, metric_value:, app_name:, attrs: {})
    tags = get_tags(app_name, attrs)
    stat_name = get_stat_name(metric_group, metric_name)
    @statsd.gauge(stat_name, metric_value, tags: tags)

    # Dynatrace statD implementation
    StatsD.gauge(stat_name, metric_value, tags: tags)
  end

  # :nocov:
  # :reek:LongParameterList
  def self.histogram(metric_group:, metric_name:, metric_value:, app_name:, attrs: {})
    tags = get_tags(app_name, attrs)
    stat_name = get_stat_name(metric_group, metric_name)
    @statsd.histogram(stat_name, metric_value, tags: tags)

    # Dynatrace statD implementation
    StatsD.histogram(stat_name, metric_value, tags: tags)
  end
  # :nocov:

  private_class_method def self.get_stat_name(metric_group, metric_name)
    "dsva-appeals.#{metric_group}.#{metric_name}"
  end

  private_class_method def self.get_tags(app_name, attrs)
    extra_tags = attrs.reduce([]) do |tags, (key, val)|
      tags + ["#{key}:#{val}"]
    end
    [
      "app:#{app_name}",
      "env:#{Rails.current_env}"
    ] + extra_tags
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  # :reek:LongParameterList
  def self.record(description, service: nil, name: "unknown", caller: nil)
    return_value = nil
    app = RequestStore[:application] || "other"

    Rails.logger.info("STARTED #{description}")
    stopwatch = Benchmark.measure do
      return_value = yield
    end

    if service
      latency = stopwatch.real
      sent_to_info = {
        metric_group: "service",
        metric_name: "request_latency",
        metric_value: latency,
        app_name: app,
        attrs: {
          service: service ||= app,
          endpoint: name
        }
      }
      MetricsService.emit_gauge(sent_to_info)
    end

    Rails.logger.info("FINISHED #{description}: #{stopwatch}")

    return_value
  rescue StandardError => error
    Rails.logger.error("#{error.message}\n#{error.backtrace.join("\n")}")
    Raven.capture_exception(error, extra: { type: "request_error", service: service, name: name, app: app })

    increment_metrics_service_counter("request_error", service, name, app) if service

    # Re-raise the same error. We don't want to interfere at all in normal error handling.
    # This is just to capture the metric.
    raise
  ensure
    increment_metrics_service_counter("request_attempt", service, name, app) if service
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  private_class_method def self.increment_metrics_service_counter(metric_name, service, endpoint_name, app_name)
    increment_counter(
      metric_group: "service",
      metric_name: metric_name,
      app_name: app_name,
      attrs: {
        service: service,
        endpoint: endpoint_name
      }
    )
  end
end