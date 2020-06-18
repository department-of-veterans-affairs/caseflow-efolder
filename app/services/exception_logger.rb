class ExceptionLogger
  DEPENDENCY_MAINTENANCE = [/Could not get JDBC Connection/,
                            /Maintenance.+VBMS/,
                            /upstream connect error or disconnect/,
                            /A system error occurred/].freeze

  def self.capture(error)
    Rails.logger.error "#{error.message}\n#{error.backtrace&.join("\n")}"
    Raven.capture_exception(error) unless ignore_exception?(error)
  end

  # Do not send Sentry alerts when external systems are in maintenance mode
  def self.ignore_exception?(error)
    error.ignorable? || DEPENDENCY_MAINTENANCE.select { |m| m =~ error_message(error) }.present?
  end

  def self.error_message(error)
    error.to_s.encode("UTF-8", invalid: :replace, replace: "")
  end
end
