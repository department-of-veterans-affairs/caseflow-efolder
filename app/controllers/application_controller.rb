class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  force_ssl if: :ssl_enabled?
  before_action :authenticate
  before_action :authorize
  before_action :configure_bgs
  before_action :strict_transport_security

  def authenticate
    redirect_to "/auth/samlva" if current_user.nil?
  end

  def authorize
    redirect_to "/unauthorized" unless current_user.can? "Download eFolder"
  end

  def current_user
    return nil if session["user"].nil?

    User.new session["user"].merge(ip_address: request.remote_ip)
  end
  helper_method :current_user

  private

  def ssl_enabled?
    Rails.env.production? && !(request.path =~ /health-check/)
  end

  def strict_transport_security
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains" if request.ssl?
  end

  def configure_bgs
    BGSService.user = current_user
  end
end
