# frozen_string_literal: true

# Wraps known BGS errors so that we can better triage what gets reported in Sentry alerts.
class BGSError < DependencyError
  KNOWN_ERRORS = {
    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/3156/
    /Connection timed out - connect\(2\) for "bepprod\.vba\.va\.gov" port 443/ => "BGSError::Transient",

    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/3153/
    /Connection refused - connect\(2\) for "bepprod\.vba\.va\.gov" port 443/ => "BGSError::Transient",

    # BGS kills connection
    #
    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/3158/
    /HTTPClient::KeepAliveDisconnected: Connection reset by peer/ => "BGSError::Transient",

    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/3621/
    /Connection reset by peer/ => "BGSError::Transient",

    # Examples: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/3170/
    /Unable to find SOAP operation:/ => "BGSError::Transient",

    # Transient failure when, for example, a WSDL is unavailable.
    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/3167/
    /HTTP error \(504\): upstream request timeout/ => "BGSError::Transient",

    # Like above
    #
    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/667/
    /HTTP error \(503\): upstream connect error/ => "BGSError::Transient",

    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3188/
    /TUX-20306 - An unexpected error was encountered/ => "BGSError::Transient"
  }.freeze
end
# Many BGS calls fail in off-hours because BGS has maintenance time. These errors are classified
# as transient errors and we ignore them in our reporting tools.

class BGSError::Transient < BGSError; end
