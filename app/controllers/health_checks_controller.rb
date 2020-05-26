class HealthChecksController < ApplicationController
  include CollectDataDogMetrics
  skip_before_action :authenticate
  skip_before_action :check_out_of_service
  newrelic_ignore_apdex

  def show
    body = {
      healthy: true
    }.merge(Rails.application.config.build_version || {})
    render(json: body, status: :ok)
  end
end
