class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  force_ssl if: :ssl_enabled?
  before_action :authenticate
  before_action :set_raven_user
  before_action :configure_bgs
  before_action :strict_transport_security

  def authenticate
    return true unless current_user.nil?

    session["return_to"] = request.original_url
    redirect_to((ENV["SSO_HOST"] || "") + "/auth/samlva")
  end

  def set_raven_user
    if current_user && ENV["SENTRY_DSN"]
      # Raven sends error info to Sentry.
      Raven.user_context(
        id: current_user.id,
        email: current_user.email,
        ip_address: current_user.ip_address,
        station_id: current_user.station_id
      )
    end
  end

  def authorize_system_admin
    redirect_to "/unauthorized" unless current_user.can? "System Admin"
  end

  def authorize
    redirect_to "/unauthorized" unless current_user.can? "Download eFolder"
  end

  private

  def current_user
    @current_user ||= User.from_session(session, request)
  end
  helper_method :current_user

  def ssl_enabled?
    Rails.env.production? && !(request.path =~ /health-check/)
  end

  def strict_transport_security
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains" if request.ssl?
  end

  def configure_bgs
    Download.bgs_service = BGSService.new(user: current_user) unless Rails.env.test?
  end

  def feedback_url
    unless ENV["CASEFLOW_FEEDBACK_URL"]
      return "https://vaww.vaco.portal.va.gov/sites/BVA/olkm/DigitalService/Lists/Feedback/NewForm.aspx"
    end

    param_object = { redirect: request.original_url, subject: "eFolder Express" }

    ENV["CASEFLOW_FEEDBACK_URL"] + "?" + param_object.to_param
  end
  helper_method :feedback_url
end
