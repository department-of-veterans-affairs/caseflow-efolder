class HealthChecksController < ApplicationController
  include CollectCustomMetrics
  skip_before_action :authenticate
  skip_before_action :check_out_of_service

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
      migrations << { status: status, version: version, name: name }
      pending_migrations = true if status != "up"
    end
    { migrations: migrations, pending_migrations: pending_migrations }
  end

end
