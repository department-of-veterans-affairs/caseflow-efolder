class BaseController < ActionController::Base
  force_ssl if: :ssl_enabled?
  before_action :strict_transport_security
  before_action :current_user

  private

  def ssl_enabled?
    Rails.env.production? && !(request.path =~ /health-check/)
  end

  def strict_transport_security
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains" if request.ssl?
  end

  def current_user=(user)
    RequestStore.store[:current_user] = user
    @current_user = user
  end

  def current_user
    @current_user || self.current_user = User.from_session(session, request)
  end
  helper_method :current_user

  def configure_bgs
    Thread.current[:bgs_service] = BGSService.new(user: current_user)
  end

  class << self
    def dependencies_faked?
      (Rails.env.development? || Rails.env.test? || Rails.env.demo?) && Rails.env != 'staging'
    end
  end
end
