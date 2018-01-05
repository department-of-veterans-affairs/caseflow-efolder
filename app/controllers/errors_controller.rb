class ErrorsController < ApplicationController
  skip_before_action :verify_authentication

  def server_error
    status_code = params[:status_code]
    template_name = "errors/server_error"
    render template: template_name, status: status_code, formats: :html
    raise StandardError
  end

end
