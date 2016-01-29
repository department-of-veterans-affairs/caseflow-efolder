require 'vbms'

# Thin interface to all things VBMS
class VBMSService
  def self.fetch_documents_for(download)
    @client ||= init_client

    request = VBMS::Requests::ListDocuments.new(download.file_number)
    @client.send_request(request)
  rescue
    raise VBMS::ClientError
  end

  def self.fetch_document_file(document)
    @client ||= init_client

    request = VBMS::Requests::FetchDocumentById.new(document.document_id)
    result = @client.send_request(request)
    result && result.content
  rescue
    raise VBMS::ClientError
  end

  private

  def self.init_client
    vbms_config = Rails.application.secrets.vbms

    VBMS::Client.new(
      vbms_config["url"],
      File.join(vbms_config["env_dir"], vbms_config["keyfile"]),
      File.join(vbms_config["env_dir"], vbms_config["saml"]),
      File.join(vbms_config["env_dir"], vbms_config["key"]),
      vbms_config["keypass"],
      File.join(vbms_config["env_dir"], vbms_config["cacert"]),
      File.join(vbms_config["env_dir"], vbms_config["cert"])
    )
  end
end