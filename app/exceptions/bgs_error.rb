# frozen_string_literal: true


# Wraps known BGS errors so that we can better triage what gets reported in Sentry alerts.
class BGSError < StandardError

  def initialize(error)
    super(error.message).tap do |result|
      result.set_backtrace(error.backtrace)
    end
  end

  KNOWN_ERRORS = {
    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/3156/
    /Connection timed out - connect\(2\) for "bepprod\.vba\.va\.gov" port 443/ => "TransientBGSError",

    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/3153/
    /Connection refused - connect\(2\) for "bepprod\.vba\.va\.gov" port 443/ => "TransientBGSError",

    # BGS kills connection
    #
    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/3158/
    /HTTPClient::KeepAliveDisconnected: Connection reset by peer/ => "TransientBGSError",

    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/3621/
    /Connection reset by peer/ => "TransientBGSError",

    # Examples: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/3170/
    /Unable to find SOAP operation:/ => "TransientBGSError",

    # Transient failure when, for example, a WSDL is unavailable. 
    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/3167/
     /HTTP error \(504\): upstream request timeout/ => "TransientBGSError",

    # Like above
    #
    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/efolder/issues/667/
    /HTTP error \(503\): upstream connect error/ => "TransientBGSError",

    # Example: https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3188/
    /TUX-20306 - An unexpected error was encountered/ => "TransientBGSError"
  }.freeze


  class << self
    def from_bgs_error(bgs_error)
      bgs_error_message = extract_error_message(bgs_error)
      new_error = nil
      KNOWN_ERRORS.each do |msg_str, error_class_name|
        next unless bgs_error_message.match(msg_str)

        error_class = "#{error_class_name}".constantize

        new_error = error_class.new(bgs_error)
        break
      end
      new_error ||= new(bgs_error)
    end

    private

    def extract_error_message(bgs_error)
      if bgs_error.try(:body)
        # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3124/
        bgs_error.body.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
      else
        bgs_error.message
      end
    end
  end
end
# Many BGS calls fail in off-hours because BGS has maintenance time. These errors are classified
# as transient errors and we ignore them in our reporting tools. 
class TransientBGSError < BGSError; end