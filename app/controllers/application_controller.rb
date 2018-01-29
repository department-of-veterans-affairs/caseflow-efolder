class ApplicationController < BaseController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :check_out_of_service
  before_action :authenticate
  before_action :set_raven_user

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
    redirect_to "/unauthorized" unless current_user.admin?
  end

  def authorize
    redirect_to "/unauthorized" unless current_user.can? "Download eFolder"
  end

  private

  def check_out_of_service
    out_of_service_path = "/react/out-of-service"
    react_enabled = FeatureToggle.enabled?(:efolder_react_app, user: current_user) || Rails.env.development?
    redirect_to out_of_service_path if Rails.cache.read("out_of_service") && request.path != out_of_service_path && react_enabled

    render "out_of_service", layout: "application" if Rails.cache.read("out_of_service")
  end

  def feedback_url
    return "https://vaww.vaco.portal.va.gov/sites/BVA/olkm/DigitalService/Lists/Feedback/NewForm.aspx" unless ENV["CASEFLOW_FEEDBACK_URL"]

    param_object = { redirect: request.original_url, subject: "eFolder Express" }

    ENV["CASEFLOW_FEEDBACK_URL"] + "?" + param_object.to_param
  end
  helper_method :feedback_url

  def vva_feature_enabled?
    BaseController.dependencies_faked? || FeatureToggle.enabled?(:vva_service, user: current_user)
  end
  helper_method :vva_feature_enabled?
end
