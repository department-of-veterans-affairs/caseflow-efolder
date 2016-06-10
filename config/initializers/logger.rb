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
logger_path = config.paths["log"].first
rollover_logger = Logger.new(logger_path, 10, 1.megabyte)
Rails.logger = ActiveSupport::TaggedLogging.new(rollover_logger) unless Rails.env.development?

# log sidekiq to application logger (defaults to stdout)
Sidekiq::Logging.logger = Rails.logger
# :nocov:
