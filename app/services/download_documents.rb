require 'vbms'

class DownloadDocuments
  def initialize(opts = {})
    @download = opts[:download]
    @vbms_documents = opts[:vbms_documents]
  end

  def perform
    create_documents
    download_document_contents
  end

  def create_documents
    @vbms_documents.each do |vbms_document|
      @download.documents.create!(
        document_id: vbms_document.document_id,
        filename: vbms_document.filename,
        doc_type: vbms_document.doc_type,
        source: vbms_document.source,
        mime_type: vbms_document.mime_type,
        received_at: vbms_document.received_at
      )
    end
  end

  def download_document_contents
    @download.documents.each do |document|
      begin
        content = VBMSService.fetch_document_file(document)
        filename = save_document_file(document, content)
        document.update_attributes!(filename: filename, download_status: :success)  
      rescue 
        document.update_attributes!(download_status: :failed)  
      end
    end 
  end

  def basepath 
    basepath = Rails.application.config.download_filepath
    Dir.mkdir(basepath) unless File.exists?(basepath)

    basepath
  end

  def save_document_file(document, content)
    filepath = File.join(basepath, document.document_id)
    Dir.mkdir(filepath) unless File.exists?(filepath)

    filename = File.join(filepath, document.filename)
    File.open(filename, 'w') do |f|
      f.puts content
    end

    filename
  end
end