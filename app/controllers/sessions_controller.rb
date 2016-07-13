class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]
  skip_before_action :authenticate, only: [:create]
  skip_before_action :authorize

  def create
    session["user"] = User.from_css_auth_hash auth_hash

    redirect_to session.delete("return_to") || "/"
  end

  def destroy
    session["user"] = nil
    redirect_to "/"
  end

  protected

  def auth_hash
    request.env["omniauth.auth"]
  end
end
