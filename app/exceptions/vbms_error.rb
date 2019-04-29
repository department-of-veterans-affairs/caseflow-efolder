# frozen_string_literal: true

# Wraps known VBMS errors so that we can better triage what gets reported in Sentry alerts.
class VBMSError < DependencyError
  class Transient < VBMSError; end
  class DocumentNotFound < VBMSError; end
  class ResultSetTooBig < VBMSError; end

  KNOWN_ERRORS = {
    # https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/4812/events/314288/
    /Requested result set exceeds acceptable size/ => "VBMSError::ResultSetTooBig",

    /Document not found/ => "VBMSError::DocumentNotFound",

    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/2161/
    /HTTPClient::ReceiveTimeoutError: execution expired/ => "VBMSError::Transient",

    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/2322/
    /HTTPClient::SendTimeoutError: execution expired/ => "VBMSError::Transient",

    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/4708/
    /HTTPClient::KeepAliveDisconnected:/ => "VBMSError::Transient",

    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/2847/
    /HTTPClient::ConnectTimeoutError: execution expired/ => "VBMSError::Transient",

    # Examples: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/3170/
    /Unable to find SOAP operation:/ => "VBMSError::Transient",

    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/2557/
    /Connection reset by peer - SSL_connect/ => "VBMSError::Transient"
  }.freeze
end
