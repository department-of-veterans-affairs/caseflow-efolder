class ApplicationController < BaseController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :check_out_of_service
  before_action :authenticate
  before_action :set_raven_user
  before_action :check_v2_app_access

  def serve_single_page_app
    render "gui/single_page_app", layout: false
  end

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
    redirect_to "/unauthorized" unless user_is_authorized?
  end

  def check_v2_app_access
    serve_single_page_app if can_access_react_app?
  end

  def initial_react_data
    {
      csrfToken: form_authenticity_token,
      dropdownUrls: dropdown_urls,
      efolderAccessImagePath: ActionController::Base.helpers.image_path("help/efolder-access.png"),
      feedbackUrl: feedback_url,
      recentDownloads: recent_downloads.sort_by(&:created_at).reverse,
      referenceGuidePath: ActionController::Base.helpers.asset_path("reference_guide.pdf"),
      trainingGuidePath: ActionController::Base.helpers.asset_path("training_guide.pdf"),
      userDisplayName: current_user.try(:display_name),
      userIsAuthorized: user_is_authorized?
    }.to_json
  end
  helper_method :initial_react_data

  def dropdown_urls
    [
      {
        title: "Help",
        link: url_for(controller: "/help", action: "show")
      },
      {
        title: "Send Feedback",
        link: feedback_url,
        target: "_blank"
      },
      {
        title: "Sign out",
        link: url_for(controller: "/sessions", action: "destroy")
      }
    ]
  end

  private

  def user_is_authorized?
    current_user.try(:can?, "Download eFolder") || Rails.env.development?
  end

  def can_access_react_app?
    FeatureToggle.enabled?(:efolder_react_app, user: current_user) || Rails.env.development?
  end

  def downloads
    Download.active.where(user: current_user)
  end

  # TODO: This will need to be replaced by a similar function for UserManifests
  # efolder issue 813 addresses this requirement.
  def recent_downloads
    @recent_downloads ||= downloads.where(status: [3, 4, 5, 6])
  end

  def check_out_of_service
    out_of_service_path = "/out-of-service"
    if Rails.cache.read("out_of_service") && request.path != out_of_service_path
      redirect_to(out_of_service_path) && return if can_access_react_app?
      render "out_of_service", layout: "application"
    end
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
