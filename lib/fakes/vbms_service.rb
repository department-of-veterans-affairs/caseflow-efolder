class Fakes::VBMSService < Fakes::DocumentService
  @service_type = "VBMS"

  def self.raise_error
    fail VBMS::ClientError
  end
end
