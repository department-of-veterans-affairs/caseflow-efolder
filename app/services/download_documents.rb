require "vbms"
require "vva"
require "zip"

# support files larger than 4G
Zip.write_zip64_support = true

class DownloadDocuments
  include Caseflow::DocumentTypes

  def initialize(opts = {})
    @download = opts[:download]
    @external_documents = DocumentFilter.new(documents: opts[:external_documents]).filter
  end

  def create_documents
    Download.transaction do
      @external_documents.each do |external_document|
        # JRO and SSN are required when searching for a document in VVA
        type_id = external_document.try(:doc_type) || external_document.type_id
        @download.documents.find_or_initialize_by(document_id: external_document.document_id).tap do |t|
          t.assign_attributes(
            vbms_filename: external_document.filename,
            type_id: type_id,
            type_description: external_document.try(:type_description) || TYPES[type_id.to_i],
            source: external_document.source,
            mime_type: external_document.mime_type,
            received_at: external_document.received_at,
            jro: external_document.try(:jro),
            ssn: external_document.try(:ssn),
            downloaded_from: external_document.try(:downloaded_from) || "VBMS"
          )
          t.save!
        end
      end

      # TODO(alex): do we still need this field? why are we setting it here?
      @download.update_attributes!(manifest_fetched_at: Time.zone.now)
    end
  end

  def download_contents(save_locally: true)
    begin
      @download.update_attributes!(started_at: Time.zone.now)
    rescue ActiveRecord::StaleObjectError
      Rails.logger.info "Duplicate download detected. Download ID: #{@download.id}"
      return false
    end

    @download.documents.where(download_status: 0).each do |document|
      before_document_download(document)
      fetch_result = document.fetch_content!(save_document_metadata: true)
      document.save_locally(fetch_result[:content]) if save_locally && !fetch_result[:error_kind]

      return false if fetch_result[:error_kind] == :caseflow_efolder_error
      @download.touch
    end
  end

  def fetch_from_s3(document)
    # if the file exists on the filesystem, skip
    return if File.exist?(document.path)

    S3Service.fetch_file(document.s3_filename, document.path)
  end

  def zip_exists_locally?
    File.exist?(zip_path)
  end

  def stream_zip_from_s3
    S3Service.stream_content(streaming_s3_key)
  end

  def streaming_s3_key
    Rails.application.config.s3_enabled ? @download.s3_filename : zip_path
  end

  def zip_path
    File.join(@download.download_dir, @download.package_filename)
  end

  def package_contents
    before_package_contents
    @download.update_attributes(status: :packaging_contents)

    File.delete(zip_path) if zip_exists_locally?

    Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
      @download.documents.success.each_with_index do |document, index|
        fetch_from_s3(document)
        zipfile.add(document.unique_filename(index), document.path)
      end
    end

    S3Service.store_file(@download.s3_filename, zip_path, :filepath)
    @download.complete!(File.size(zip_path))

    cleanup!
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

  private

  def cleanup!
    files = Dir["#{@download.download_dir}/*"].reject do |filepath|
      filepath.end_with?(@download.package_filename)
    end

    FileUtils.rm files
  end
end
