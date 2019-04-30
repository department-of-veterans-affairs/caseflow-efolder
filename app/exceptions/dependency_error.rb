# frozen_string_literal: true

# Parent wrapper class for dependencies errors
class DependencyError < StandardError
  def initialize(error)
    super(error.message).tap do |result|
      result.set_backtrace(error.backtrace)
    end
  end

  class << self
    def from_dependency_error(error)
      error_message = extract_error_message(error)
      new_error = nil
      self::KNOWN_ERRORS.each do |msg_str, error_class_name|
        next unless error_message.match(msg_str)

        error_class = error_class_name.to_s.constantize

        new_error = error_class.new(error)
        break
      end
      new_error ||= new(error)
    end

    private

    def extract_error_message(error)
      msg = if error.try(:body)
              # https://sentry.ds.va.gov/department-of-veterans-affairs/caseflow/issues/3124/
              error.body.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
            else
              error.message
            end
      "#{error.class}: #{msg}"
    end
  end
end
