# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module ApplicationHelper
  def ui_user?
    return false unless RequestStore[:current_user]
    (RequestStore[:current_user].roles || []).include?("Download eFolder")
  end

  def current_ga_path
    full_path = request.env["PATH_INFO"]

    begin
      route = Rails.application.routes.recognize_path(full_path)
      return full_path unless route
      ["", route[:controller], route[:action]].join("/")

    # no match in recognize_path
    rescue ActionController::RoutingError
      full_path
    end
  end
end
# rubocop:enable Metrics/ModuleLength
