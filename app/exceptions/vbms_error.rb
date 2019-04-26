# frozen_string_literal: true

# Wraps known BGS errors so that we can better triage what gets reported in Sentry alerts.
class VBMSError < DependencyError
  KNOWN_ERRORS = {
    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/2161/
    /HTTPClient::ReceiveTimeoutError: exection expired/ => "TransientVBMSError",

    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/2322/
    /HTTPClient::SendTimeoutError: exection expired/ => "TransientVBMSError",

    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/4708/
    /HTTPClient::KeepAliveDisconnected:/ => "TransientVBMSError",

    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/2847/
    /HTTPClient::ConnectTimeoutError: exection expired/ => "TransientVBMSError",

    # Examples: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/3170/
    /Unable to find SOAP operation:/ => "TransientVBMSError",

    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/4713/
    /Connection refused - connect\(2\) for "localhost" port 10001/ => "ECONNREFUSEDVBMSError",

    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/2557/
    /Connection reset by peer - SSL_connect/ => "ECONNRESETVBMSError"
  }.freeze
end
# Many BGS calls fail in off-hours because BGS has maintenance time. These errors are classified
# as transient errors and we ignore them in our reporting tools.

class TransientVBMSError < VBMSError; end
class ECONNREFUSEDVBMSError < VBMSError; end
class ECONNRESETVBMSError < VBMSError; end
