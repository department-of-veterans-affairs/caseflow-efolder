class ErrorsController < BaseController
  skip_before_action :authenticate

  def show
    status_code = params[:status_code]
    template_name = "errors/server_error"
    render template: template_name, status: status_code, format: :html
  end
end

