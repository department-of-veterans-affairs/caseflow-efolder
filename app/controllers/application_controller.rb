class ApplicationController < BaseController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :check_out_of_service
  before_action :authenticate
  before_action :set_raven_user
  before_action :configure_bgs

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

  private

  def check_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("out_of_service")
  end

  def configure_bgs
    Download.bgs_service = ExternalApi::BGSService.new(user: current_user) unless Rails.env.test?
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
