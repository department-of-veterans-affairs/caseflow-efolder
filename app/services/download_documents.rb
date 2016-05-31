require "vbms"
require "zip"

class DownloadDocuments
  def initialize(opts = {})
    @download = opts[:download]
    @vbms_documents = opts[:vbms_documents] || []
    @vbms_service = opts[:vbms_service] || VBMSService
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

  def download_contents
    @download.documents.each_with_index do |document, i|
      begin
        content = @vbms_service.fetch_document_file(document)
        filepath = save_document_file(document, content, i)
        document.update_attributes!(filepath: filepath, download_status: :success)
      rescue VBMS::ClientError
        document.update_attributes!(download_status: :failed)
      end
    end
  end

  def download_dir
    return @download_dir if @download_dir

    basepath = Rails.application.config.download_filepath
    Dir.mkdir(basepath) unless File.exist?(basepath)

    @download_dir = File.join(basepath, @download.id.to_s)
    Dir.mkdir(@download_dir) unless File.exist?(@download_dir)

    @download_dir
  end

  def save_document_file(document, content, index)
    filename = File.join(download_dir, "#{index}-#{document.filename}")
    File.open(filename, "wb") do |f|
      f.write(content)
    end

    filename
  end

  def zip_path
    File.join(download_dir, "documents.zip")
  end

  def package_contents
    Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
      @download.documents.success.each do |document|
        zipfile.add(document.filename, document.filepath)
      end
    end

    @download.update_attributes(status: :complete)
  end
end
