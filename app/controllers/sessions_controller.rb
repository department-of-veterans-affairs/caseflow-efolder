class SessionsController < ApplicationController
  skip_before_action :check_out_of_service
  skip_before_action :verify_authenticity_token, only: [:create, :failure, :login, :login_creds]
  skip_before_action :authenticate, only: [:create, :failure, :login, :login_creds]
  skip_before_action :check_v2_app_access

  class MissingSAMLRequest < StandardError; end

  ## Auth flow
  ##
  ## original unauthenticated request -> /login
  ## /login -> POST /login (login_creds), captures username/station_id (both optional)
  ## /login_creds -> GET /auth/samlva
  ## /auth/samlva -> GET SAML IdP
  ## SAML IdP -> POST /auth/saml_callback (create method below)
  ## /auth/saml_callback -> original request

  # GET form to allow user to assert a username/station_id
  def login
    redirect_to "/" if current_user.present?
  end

  # POST to set username/station_id and redirect to SAML login
  def login_creds
    session_login["username"] = params.permit(:username)[:username]&.strip if allow_assert_username?
    session_login["station_id"] = params.permit(:station_id)[:station_id]&.strip

    redirect_to url_for_sso_host("/auth/samlva")
  end

  def create
    fail MissingSAMLRequest unless css_auth_hash.present?

    session["user"] = build_user

    will_redirect_to = session.delete("return_to") || url_for_sso_host("/")

    # avoid UX pitfall if user starts at /login
    will_redirect_to = url_for_sso_host("/") if will_redirect_to == url_for_sso_host("/login")

    Rails.logger.info("Authenticated session for #{session['user']['css_id']} will redirect to #{will_redirect_to}")

    redirect_to will_redirect_to
  rescue StandardError => error
    Rails.logger.error("#{error}\n#{error.backtrace.join("\n")}")
    flash[:error] = error
    redirect_to url_for_sso_host("/login")
  end

  # omniauth endpoint for invalid saml tickets
  def failure
    flash[:error] = "There was a problem authenticating your PIV." # params.permit(:message)[:message] is not helpful UX
    redirect_to url_for_sso_host("/login")
  end

  def destroy
    reset_session
    RequestStore[:current_user] = nil
    redirect_to "/"
  end

  def me
  end

  protected

  def url_for_sso_host(path)
    (ENV["SSO_HOST"] || "") + path
  end

  def allow_assert_username?
    !Rails.deploy_env?(:prod)
  end
  helper_method :allow_assert_username?

  def css_auth_hash
    request.env["omniauth.auth"]
  end

  def session_login
    session["login"] ||= {}
  end

  def username
    # never allow username override in AWS prod env.
    return nil unless allow_assert_username?

    session_login["username"] || params.permit(:username)[:username]
  end

  def station_id
    session_login["station_id"] || params.permit(:station_id)[:station_id]
  end

  def build_user
    CssAuthenticationSession.from_iam_auth_hash(css_auth_hash, username, station_id).as_json
  end
end
