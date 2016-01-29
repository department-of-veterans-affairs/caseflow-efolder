require 'vbms'

# Thin interface to all things VBMS
class VBMSService
  def self.fetch_document_listing(file_number)
    @client ||= init_client

    # TODO: download the document list for the download and return it as a list of VBMS::Responses::Document
  rescue
    raise VBMS::ClientError
  end

  def self.fetch_document_contents(document_id)
    @client ||= init_client

    # TODO: download the document file and return it as a String
  rescue
    raise VBMS::ClientError
  end

  private

  def self.init_client
    vbms_config = Rails.application.secrets.vbms

    VBMS::Client.new(
      vbms_config["url"],
      vbms_config["env_dir"],
      vbms_config["keyfile"],
      vbms_config["saml"],
      vbms_config["keypass"],
      vbms_config["cacert"],
      vbms_config["cert"]
    )
  end
end