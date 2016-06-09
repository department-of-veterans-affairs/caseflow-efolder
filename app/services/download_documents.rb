require "vbms"
require "zip"

class DownloadDocuments
  def initialize(opts = {})
    @download = opts[:download]
    @vbms_documents = opts[:vbms_documents] || []
    @vbms_service = opts[:vbms_service] || VBMSService
    @s3 = opts[:s3] || (Rails.application.config.s3_enabled ? S3Service : Fakes::S3Service)
  end

  def create_documents
    @vbms_documents.each do |vbms_document|
      @download.documents.create!(
        document_id: vbms_document.document_id,
        vbms_filename: vbms_document.filename,
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

        @s3.store_file(document.s3_filename, content)

        filepath = save_document_file(document, content, i)
        document.update_attributes!(
          filepath: filepath,
          download_status: :success
        )
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
    filename = File.join(download_dir, unique_filename(document, index))
    File.open(filename, "wb") do |f|
      f.write(content)
    end

    filename
  end

  def unique_filename(document, index)
    "#{index}-#{document.filename}"
  end

  def fetch_from_s3(document)
    # if the file exists on the filesystem, skip
    return if File.exist?(document.filepath)

    @s3.fetch_file(document.s3_filename, document.filepath)
  end

  def fetch_zip_from_s3
    # if the file exists on the filesystem, skip
    return if File.exist?(zip_path)

    @s3.fetch_file(@download.s3_filename, zip_path)
  end

  def zip_path
    File.join(download_dir, "documents.zip")
  end

  def package_contents
    Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
      @download.documents.success.each_with_index do |document, i|
        fetch_from_s3(document)
        zipfile.add(unique_filename(document, i), document.filepath)
      end
    end

    @s3.store_file(@download.s3_filename, zip_path, :filepath)

    @download.update_attributes(status: :complete)
  end
end
