class ErrorsController < ApplicationController
  skip_before_action :authenticate

  def server_error
    status_code = params[:status_code]
    template_name = "errors/server_error"
    render template: template_name, status: status_code, formats: :html
  end

end
