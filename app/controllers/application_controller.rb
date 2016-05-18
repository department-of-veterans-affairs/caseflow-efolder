class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :authenticate
  before_action :authorize

  def authenticate
    redirect_to "/auth/samlva" if current_user.nil?
  end

  def authorize
    redirect_to "/unauthorized" unless current_user.can? "Download eFolder"
  end

  helper_method :current_user

  def current_user
    return nil if session["user"].nil?
    User.new session["user"]
  end
end
