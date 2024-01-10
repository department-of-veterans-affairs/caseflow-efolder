require 'caseflow'

class Fakes::VBMSService < Efolder::Fakes::DocumentService
  def self.service_type
    "VBMS"
  end

  def self.raise_error
    raise VBMS::ClientError
  end
end
