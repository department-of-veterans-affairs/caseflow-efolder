class Api::V1::ApplicationController < BaseController
  protect_from_forgery with: :null_session
  before_action :authorize

  rescue_from StandardError do |error|
    Raven.capture_exception(error)

    render json: {
      "errors": [
        "status": "500",
        "title": "Unknown error occured",
        "detail": "#{error} (Sentry event id: #{Raven.last_event_id})"
      ]
    }, status: 500
  end

  private

  def unauthorized
    render json: { status: "unauthorized" }, status: 401
  end

  def authenticate_with_token
    @authenticate_with_token ||= authenticate_with_http_token do
      |token, _options| token == Rails.application.config.api_key
    end
  end

  def user_has_role
     current_user && (current_user.can?("Reader") || current_user.can?("System Admin"))
  end

  def authorize
    return unauthorized unless authenticate_with_token || user_has_role
  end

  def station_id
    request.headers["HTTP_STATION_ID"]
  end

  def css_id
    request.headers["HTTP_CSS_ID"]
  end

  def current_user
    return @current_user ||= User.find_or_create_by(css_id: css_id, station_id: station_id) if authenticate_with_token
    super
  end
end
