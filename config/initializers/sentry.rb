if ENV['SENTRY_DSN']
  Raven.configure do |config|
    config.dsn = ENV['SENTRY_DSN']

    # Sometimes, a VA backend will randomly fail. When we retry, it generally works.
    # We do not need to log this to Sentry, because it's not actionable for us.
    config.excluded_exceptions += ['EOFError']

    # transient errors we don't care to know about.
    config.excluded_exceptions += [
      "HTTPClient::ReceiveTimeoutError",
      "HTTPClient::KeepAliveDisconnected"
    ]

    # any class that responds to .ignorable? with true value should be ignored
    config.should_capture = lambda { |exc_or_msg| !exc_or_msg.try(:ignorable?) }
  end
end
