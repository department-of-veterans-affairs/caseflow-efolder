require "vbms"
require "zip"

class DownloadDocuments
  include Caseflow::DocumentTypes

  def initialize(opts = {})
    @download = opts[:download]
    @vbms_documents = DownloadDocuments.filter_vbms_documents(opts[:vbms_documents] || [])
    @vbms_service = opts[:vbms_service] || VBMSService
    @s3 = opts[:s3] || (Rails.application.config.s3_enabled ? Caseflow::S3Service : Caseflow::Fakes::S3Service)
  end

  def create_documents
    Download.transaction do
      @vbms_documents.each do |vbms_document|
        @download.documents.create!(
          document_id: vbms_document.document_id,
          vbms_filename: vbms_document.filename,
          doc_type: vbms_document.doc_type,
          type_id: vbms_document.doc_type,
          type_description: vbms_document.try(:type_description) || TYPES[vbms_document.doc_type.to_i],
          source: vbms_document.source,
          mime_type: vbms_document.mime_type,
          received_at: vbms_document.received_at
        )
      end

      @download.update_attributes!(manifest_fetched_at: Time.zone.now)
    end
  end

  def fetch_document(document, index)
    document.update_attributes!(started_at: Time.zone.now)

    content = @vbms_service.fetch_document_file(document)

    @s3.store_file(document.s3_filename, content)
    filepath = save_document_file(document, content, index)
    document.update_attributes!(
      completed_at: Time.zone.now,
      filepath: filepath,
      download_status: :success
    )
  end

  def download_contents
    @download.update_attributes!(started_at: Time.zone.now)
    @download.documents.where(download_status: 0).each_with_index do |document, index|
      before_document_download(document)

      begin
        fetch_document(document, index)
        @download.touch

      rescue VBMS::ClientError => e
        document.update_attributes!(download_status: :failed)
        @download.touch
        Raven.capture_exception(e)

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

  def pdf_attributes(document)
    {
      "Document Type" => document.type_name,
      "Receipt Date" => document.received_at ? document.received_at.iso8601 : "",
      "Document ID" => document.document_id
    }
  end

  def save_document_file(document, content, index)
    filename = File.join(download_dir, unique_filename(document, index))

    if document.preferred_extension == "pdf"
      DownloadDocuments.pdf_service.write(filename, content, pdf_attributes(document))
    else
      File.open(filename, "wb") do |f|
        f.write(content)
      end
    end

    filename
  end

  def unique_filename(document, index)
    "#{format('%04d', index + 1)}0-#{document.filename}"
  end

  def fetch_from_s3(document)
    # if the file exists on the filesystem, skip
    return if File.exist?(document.filepath)

    @s3.fetch_file(document.s3_filename, document.filepath)
  end

  def zip_exists_locally?
    File.exist?(zip_path)
  end

  def fetch_zip_from_s3
    # if the file exists on the filesystem, skip
    return if zip_exists_locally?

    @s3.fetch_file(@download.s3_filename, zip_path)
  end

  def zip_path
    File.join(download_dir, @download.package_filename)
  end

  def package_contents
    before_package_contents
    @download.update_attributes(status: :packaging_contents)

    File.delete(zip_path) if zip_exists_locally?

    Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
      @download.documents.success.each_with_index do |document, index|
        fetch_from_s3(document)
        zipfile.add(unique_filename(document, index), document.filepath)
      end
    end

    @s3.store_file(@download.s3_filename, zip_path, :filepath)
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

  def self.ignored_doc_types
    [
      # C&P Exam (DBQ) sent back as both XML and PDF, ignore the XML 999981
      "999981"
    ]
  end

  # documents of type Fiduciary should not be shown
  def self.fiduciary_doc_types
    %w(
      552 600 607 601 602 546 603 604 545 605 606
      608 609 575 543 452 547 610 611 445 574 458
      535 612 614 442 595 644 615 616 541 540 456
      403 617 618 620 619 715 621 622 623 624 716
      625 626 628 629 630 631 443 632 633 634 635
      636 439 440 438 441 551 550 637 638 639 596
      640 642 643 511 402 538 645 646 647 648 544
      649 650 536 539 537 576 457 455 421 422 424
      594 425 426 169 404 454 128 429 430 431 432
      433 434 435 436 453 437 657 651 542)
  end

  def self.filter_vbms_documents(vbms_documents)
    vbms_documents.reject { |document| (ignored_doc_types + fiduciary_doc_types).include?(document.doc_type) }
  end

  class << self
    attr_writer :pdf_service

    def pdf_service
      @pdf_service ||= PdfService
    end
  end

  private

  def cleanup!
    files = Dir["#{download_dir}/*"].select do |filepath|
      !filepath.end_with?(@download.package_filename)
    end

    FileUtils.rm files
  end
end
