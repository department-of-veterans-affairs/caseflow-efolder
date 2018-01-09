# frozen_string_literal: true

class Fakes::VVAService < Fakes::DocumentService
  def self.service_type
    "VVA"
  end

  def self.raise_error
    raise VVA::ClientError
  end
end
