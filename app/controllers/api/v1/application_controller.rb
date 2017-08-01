class Api::V1::ApplicationController < BaseController
  protect_from_forgery with: :null_session
  before_action :authenticate_or_authorize

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

  def bad_request(header)
    render json: { status: "missing header: #{header}" }, status: 400
  end

  def authenticate_with_token
    @authenticate_with_token ||= authenticate_with_http_token do |token, _options|
      token == Rails.application.config.api_key
    end
  end

  def user_has_role
    current_user && (current_user.can?("Reader") || current_user.can?("System Admin"))
  end

  def authenticate_or_authorize
    # We allow users to access the API by either authenticating with the API token
    # or by making sure their user session has the Reader or System Admin role. We
    # first check to see if a user passes a token and can authenticate with it. If it
    # authenticates, then we create the current user based on the css_id and station_id
    # passed in the header. Otherwise we try to create the current user from the session
    # and authorize based on the presence of the Reader role.
    if authenticate_with_token
      return bad_request('Station ID') unless station_id
      return bad_request('CSS ID') unless css_id
      @current_user = User.find_or_create_by(css_id: css_id, station_id: station_id)
    elsif !user_has_role
      unauthorized
    end
  end

  def station_id
    request.headers["HTTP_STATION_ID"]
  end

  def css_id
    request.headers["HTTP_CSS_ID"]
  end
end
