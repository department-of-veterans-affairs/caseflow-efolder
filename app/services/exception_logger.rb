class ExceptionLogger
  DEPENDENCY_MAINTENANCE = [/Could not get JDBC Connection/,
                            /Maintenance.+VBMS/,
                            /upstream connect error or disconnect/,
                            /A system error occurred/].freeze

  def self.capture(e)
    Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
    Raven.capture_exception(e) unless ignore_exception?(e)
  end

  # Do not send Sentry alerts when external systems are in maintenance mode
  def self.ignore_exception?(e)
    DEPENDENCY_MAINTENANCE.select { |m| m =~ e.to_s }.present?
  end
end
