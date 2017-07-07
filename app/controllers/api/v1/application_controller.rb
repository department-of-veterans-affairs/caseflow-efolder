class Api::V1::ApplicationController < BaseController
  protect_from_forgery with: :null_session

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
end
