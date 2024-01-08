require 'caseflow'

class Fakes::VVAService < Caseflow::Fakes::DocumentService
  def self.service_type
    "VVA"
  end

  def self.raise_error
    raise VVA::ClientError
  end
end
