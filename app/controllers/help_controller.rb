class HelpController < ApplicationController
  before_action :authorize

  def show
    render "help"
  end
end
