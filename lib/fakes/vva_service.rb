class Fakes::VVAService < Fakes::DocumentService
  @service_type = "VVA"

  def self.raise_error
    fail VVA::ClientError
  end
end
