class BaseController < ActionController::Base
  force_ssl if: :ssl_enabled?
  before_action :strict_transport_security

  private

  def ssl_enabled?
    Rails.env.production? && !(request.path =~ /health-check/)
  end

  def strict_transport_security
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains" if request.ssl?
  end

  def current_user
    @current_user ||= User.from_session(session, request)
  end
  helper_method :current_user

  def authorize
    redirect_to "/unauthorized" unless current_user.can? "Download eFolder"
  end

  class << self
    def dependencies_faked?
      Rails.env.development? || Rails.env.test? || Rails.env.demo?
    end
  end
end
