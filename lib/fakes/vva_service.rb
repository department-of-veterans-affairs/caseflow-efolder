class Fakes::VVAService < Fakes::DocumentService
  def self.service_type
    "VVA"
  end

  def self.raise_error
    fail VVA::ClientError
  end
end
