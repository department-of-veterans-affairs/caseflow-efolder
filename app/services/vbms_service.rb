require 'vbms'

# Thin interface to all things VBMS
class VBMSService
  def self.fetch_documents_for(download)
    @client ||= init_client

    # TODO: download the document list for the download and return it as a list of VBMS::Responses::Document
  end

  def self.fetch_document_file(document)
    @client ||= init_client

    # TODO: download the document file and return it as a String
  end

  private

  def self.init_client
    raise VBMS::ClientError
  end
end