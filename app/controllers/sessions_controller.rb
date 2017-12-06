class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]
  skip_before_action :authenticate, only: [:create]

  def create
    session["user"] = AuthenticatedVisitor.from_css_auth_hash(css_auth_hash).as_json

    redirect_to session.delete("return_to") || "/"
  end

  def destroy
    session["user"] = nil
    redirect_to "/"
  end

  protected

  def css_auth_hash
    request.env["omniauth.auth"]
  end
end
