# Be sure to restart your server when you modify this file.
options = {
  key: '_caseflow_session',
  secure: Rails.env.production?,
  expire_after: 12.hours
}

options[:domain] = ENV["COOKIE_DOMAIN"] if ENV["COOKIE_DOMAIN"]

Rails.application.config.session_store :cookie_store, options
