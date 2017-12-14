if ENV['SENTRY_DSN']
  Raven.configure do |config|
    config.dsn = ENV['SENTRY_DSN']

    # Sometimes, a VA backend will randomly fail. When we retry, it generally works.
    # We do not need to log this to Sentry, because it's not actionable for us.
    config.excluded_exceptions += ['EOFError']

    # Do not send Sentry alerts when external systems are in maintenance mode
    # to test it: simulate these errors
    config.excluded_exceptions += [/Could not get JDBC Connection/, /Maintenance - VBMS/, /upstream connect error or disconnect/]
  end
end
