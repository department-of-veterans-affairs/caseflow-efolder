if ENV['SENTRY_DSN']
  Raven.configure do |config|
    config.dsn = ENV['SENTRY_DSN']

    # Sometimes, a VA backend will randomly fail. When we retry, it generally works.
    # We will explicitly rescue and retry here, because otherwise the first
    # failure will be logged to Sentry. For this error, we only want the last one
    # to be logged to Sentry.
    config.excluded_exceptions += ['EOFError']
  end
end
