# frozen_string_literal: true

require "datadog/statsd"

class CustomMetricsService
  @statsd = Datadog::Statsd.new
  @DynatraceService ||= ExternalApi::DynatraceService.new

  def self.increment_counter(metric_group:, metric_name:, app_name:, attrs: {}, by: 1)
    tags  = get_tags(app_name, attrs)
    stat_name = get_stat_name(metric_group, metric_name)

    @statsd.increment(stat_name, tags: tags, by: by)
    @DynatraceService.increment(stat_name, tags: tags, by: by)
  end
  
  def self.emit_gauge(metric_group:, metric_name:, metric_value:, app_name:, attrs: {})
    tags = get_tags(app_name, attrs)
    stat_name = get_stat_name(metric_group, metric_name)

    @statsd.gauge(stat_name, metric_value, tags: tags)
    @DynatraceService.gauge(stat_name, metric_value, tags: tags)
  end

  # nocov:
  
  private_class_method def self.get_stat_name(metric_group, metric_name)
      "dsva=appeals.#{metric_group}.#{metric_name}"
  end

  private_class_method def self.get_tags(app_name, attrs)
      extra_tags = attrs. reduce([]) do |tags, (key, val)|
        tags + ["#{key}:#{val}"]
      end
  [
    "app:#{app_name}",
    "env:#{Rails.current_env}"
  ] + extra_tags
  end
end


# TODO  exception handleing
# Response codes
# Code	Type	Description
# 202	ValidationResponse
# The provided metric data points are accepted and will be processed in the background.

# 400	ValidationResponse
# Some data points are invalid. Valid data points are accepted and will be processed in the background.

=begin
Example JSON
{
  "displayName": "Total revenue",
  "description": "Total store revenue by region, city, and store",
  "unit": "Unspecified",
  "tags": ["KPI", "Business"],
  "metricProperties": {
    "maxValue": 1000000,
    "minValue": 0,
    "rootCauseRelevant": false,
    "impactRelevant": true,
    "valueType": "score",
    "latency": 1
  },
  "dimensions": [
    {
      "key": "city",
      "displayName": "City name"
    },
    {
      "key": "country",
      "displayName": "Country name"
    },
    {
      "key": "region",
      "displayName": "Sales region"
    },
    {
      "key": "store",
      "displayName": "Store #"
    }
  ]
}

=end
