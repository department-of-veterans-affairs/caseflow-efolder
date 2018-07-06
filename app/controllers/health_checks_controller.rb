class HealthChecksController < ApplicationController
  skip_before_action :authenticate
  skip_before_action :check_v2_app_access
  newrelic_ignore_apdex

  def initialize
    @pushgateway = Caseflow::PushgatewayService.new
  end

  def healthy?
    # Check health of sidecar services
    if not Rails.deploy_env?(:prod)
      @pushgateway.healthy?
    else
      true
    end
  end

  def show
    self.healthy?

    # TODO: wire check into controller
    healthy = true

    body = {
      healthy: healthy
    }.merge(Rails.application.config.build_version || {})
    render(json: body, status: healthy ? :ok : :service_unavailable)
  end
end
