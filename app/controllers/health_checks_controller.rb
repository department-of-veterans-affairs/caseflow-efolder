class HealthChecksController < ApplicationController
  include CollectDataDogMetrics
  skip_before_action :authenticate
  skip_before_action :check_out_of_service
  newrelic_ignore_apdex

  def show
    migrations = check_migrations
    body = {
      healthy: true
    }.merge(Rails.application.config.build_version || {}).merge(migrations)
    render(json: body, status: :ok)
  end

  private
  def check_migrations
    migrations = []
    pending_migrations = false
    ActiveRecord::Base.connection.migration_context.migrations_status.each do |status, version, name|
        migrations << {status: status, version: version, name: name}
        if status != "up" then pending_migrations = true end
    end
    return {migrations: migrations, pending_migrations: pending_migrations}
  end

end
