# frozen_string_literal: true
# update
module CollectDataDogMetrics
  extend ActiveSupport::Concern
  # do we need to implement ActiveRecord support for OTEL here or in opentelemetry.rb ?
  # https://open-telemetry.github.io/opentelemetry-ruby/opentelemetry-instrumentation-active_record/v0.3.0/#label-How+do+I+get+started-3F
  # for reference

  included do
    before_action :collect_data_dog_metrics
  end

  def collect_data_dog_metrics
    collect_postgres_metrics
  end

  def collect_postgres_metrics
    conns = ActiveRecord::Base.connection_pool.connections

    active = conns.count { |c| c.in_use? && c.owner.alive? }
    dead = conns.count { |c| c.in_use? && !c.owner.alive? }
    idle = conns.count { |c| !c.in_use? }
    # update
    emit_datadog_point("postgres", "active", active)
    emit_datadog_point("postgres", "dead", dead)
    emit_datadog_point("postgres", "idle", idle)
  end
  # update
  def emit_datadog_point(db_name, type, count)
    DataDogService.emit_gauge(
      metric_group: "database",
      metric_name: "#{type}_connections",
      metric_value: count,
      app_name: "efolder",
      attrs: {
        database: db_name
      }
    )
  end
end
