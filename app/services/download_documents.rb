require 'vbms'
require 'zip'

class DownloadDocuments
  def initialize(opts = {})
    @download = opts[:download]
    @vbms_documents = opts[:vbms_documents]
  end

  def perform
    create_documents
    download_document_contents
    package_documents
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
        filepath = save_document_file(document, content)
        document.update_attributes!(filepath: filepath, download_status: :success)  
      rescue 
        document.update_attributes!(download_status: :failed)  
      end
    end 
  end

  def download_dir
    return @download_dir if @download_dir

    basepath = Rails.application.config.download_filepath
    Dir.mkdir(basepath) unless File.exists?(basepath)

    @download_dir = File.join(basepath, @download.file_number)
    Dir.mkdir(@download_dir) unless File.exists?(@download_dir)

    @download_dir
  end

  def save_document_file(document, content)
    filename = File.join(download_dir, document.filename)
    File.open(filename, 'w') do |f|
      f.puts content
    end

    filename
  end

  def package_documents
    filename = File.join(download_dir, "documents.zip")

    Zip::File.open(filename, Zip::File::CREATE) do |zipfile|
      @download.documents.success.each do |document|
        zipfile.add(document.filename, document.filepath)
      end
    end
  end
end