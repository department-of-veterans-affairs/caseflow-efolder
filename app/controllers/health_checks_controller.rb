class HealthChecksController < ApplicationController
  skip_before_action :authenticate

  def show
    render text: "Application server is healthy!"
  end
end
