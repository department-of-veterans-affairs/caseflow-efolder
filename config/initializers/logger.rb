def get_session(req)
  session_cookie_name = Rails.application.config.session_options[:key]
  req.cookie_jar.encrypted[session_cookie_name] || {}
end

log_tags = []
log_tags << lambda { |req|
  session = get_session(req)
  user = session["user"]
  ["id", "email", "station_id"].map { | attr | user[attr] }.join(" ") if user
}

# :nocov:
config = Rails.application.config

config.log_tags = log_tags

# log sidekiq to application logger (defaults to stdout)
Sidekiq::Logging.logger = Rails.logger
# :nocov:
