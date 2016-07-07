def get_session(req)
  session_cookie_name = Rails.application.config.session_options[:key]
  req.cookie_jar.encrypted[session_cookie_name] || {}
end

log_tags = []
log_tags << lambda { |req|
  session = get_session(req)
  session["user"]
}

# :nocov:
config = Rails.application.config
config.log_tags = log_tags

# don't mix worker and RAILS http logs
if !ENV["IS_WORKER"].blank?
  config.paths["log"] = "log/efolder-express-worker.log"
end

# roll logger over every 1MB, retain 10
unless Rails.env.development?
  logger_path = config.paths["log"].first
  rollover_logger = Logger.new(logger_path, 10, 1.megabyte)
  Rails.logger = rollover_logger

  # set the format again in case it was overwritten
  Rails.logger.formatter = config.log_formatter if config.log_formatter

  # recreate the logger with Tagged support which Rails expects
  Rails.logger = ActiveSupport::TaggedLogging.new(Rails.logger)
end

# log sidekiq to application logger (defaults to stdout)
Sidekiq::Logging.logger = Rails.logger
# :nocov:
