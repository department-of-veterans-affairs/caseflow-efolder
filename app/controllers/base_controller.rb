class BaseController < ActionController::Base
  before_action :strict_transport_security
  before_action :current_user

  private

  def strict_transport_security
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains" if request.ssl?
  end

  def current_user=(user)
    RequestStore.store[:current_user] = user
    @current_user = user
  end

  def current_user
    @current_user ||= self.current_user = User.from_session_and_request(session, request)
  end
  helper_method :current_user

  class << self
    def dependencies_faked?
      Rails.env.development? || Rails.env.test? || Rails.env.demo?
    end

    def dependencies_faked_for_CEAPI?
      Rails.env.development? || Rails.env.demo?
    end
  end
end
