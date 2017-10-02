class Fakes::VBMSService < Fakes::DocumentService
  def self.service_type
    "VBMS"
  end

  def self.raise_error
    fail VBMS::ClientError
  end
end
