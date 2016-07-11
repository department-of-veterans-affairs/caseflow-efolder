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
    @download.documents.where(download_status: 0).each_with_index do |document, i|
      before_document_download(document)

      begin
        document.update_attributes!(started_at: Time.zone.now)

        content = @vbms_service.fetch_document_file(document)

        @s3.store_file(document.s3_filename, content)
        filepath = save_document_file(document, content, i)
        document.update_attributes!(
          completed_at: Time.zone.now,
          filepath: filepath,
          download_status: :success
        )

      rescue VBMS::ClientError
        document.update_attributes!(download_status: :failed)

      rescue ActiveRecord::StaleObjectError
        Rails.logger.info "Duplicate download detected. Document ID: #{document.id}"
        return false
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
    "#{format('%04d', index)}0-#{document.filename}"
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
    before_package_contents
    @download.update_attributes(status: :packaging_contents)

    File.delete(zip_path) if File.exist?(zip_path)

    Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
      @download.documents.success.each_with_index do |document, index|
        fetch_from_s3(document)
        zipfile.add(unique_filename(document, index), document.filepath)
      end
    end

    @s3.store_file(@download.s3_filename, zip_path, :filepath)

    @download.update_attributes(
      status: @download.errors? ? :complete_with_errors : :complete_success
    )

  rescue ActiveRecord::StaleObjectError
    Rails.logger.info "Duplicate packaging detected. Download ID: #{@download.id}"
  end

  def download_and_package
    package_contents if download_contents
  end

  def before_document_download(document)
    # Test hook for testing race conditions
  end

  def before_package_contents
    # Test hook for testing race conditions
  end
end
