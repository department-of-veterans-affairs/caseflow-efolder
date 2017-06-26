class Api::V1::ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  force_ssl if: :ssl_enabled?
  before_action :strict_transport_security

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

  def streaming_headers(mime_type, filename)
    headers["Content-Type"] = mime_type
    headers["Content-disposition"] = "attachment; filename=\"#{filename}\""

    # Setting this to "no" will allow unbuffered responses for HTTP streaming applications
    headers["X-Accel-Buffering"] = "no"
    headers["Cache-Control"] ||= "no-cache"
  end

  def ssl_enabled?
    Rails.env.production?
  end

  def strict_transport_security
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains" if request.ssl?
  end

  def unauthorized
    render json: { status: "unauthorized" }, status: 401
  end
end
