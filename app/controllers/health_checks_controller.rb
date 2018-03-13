class HealthChecksController < ApplicationController
  skip_before_action :authenticate
  skip_before_action :check_v2_app_access
  newrelic_ignore_apdex

  def show
    render json: { healthy: true }.merge(Rails.application.config.build_version || {})
  end
end
