require "vbms"
require "vva"
require "zip"

class DownloadDocuments
  include Caseflow::DocumentTypes

  # C&P Exam (DBQ) sent back as both XML and PDF, ignore the XML 999981
  IGNORED_DOC_TYPES = %w[999981].freeze

  # documents of type Fiduciary should not be shown
  FIDUCIARY_DOC_TYPES = %w[
    552 600 607 601 602 546 603 604 545 605 606
    608 609 575 543 452 547 610 611 445 574 458
    535 612 614 442 595 644 615 616 541 540 456
    403 617 618 620 619 715 621 622 623 624 716
    625 626 628 629 630 631 443 632 633 634 635
    636 439 440 438 441 551 550 637 638 639 596
    640 642 643 511 402 538 645 646 647 648 544
    649 650 536 539 537 576 457 455 421 422 424
    594 425 426 169 404 454 128 429 430 431 432
    433 434 435 436 437 657 651 542 444 548
    549
  ].freeze

  # documents of types IRS/SSA, IVM and Financial Actions should not be shown
  RESTRICTED_VVA_DOC_TYPES = %w[
    804 807 808 809 810 811 812 813 814 815 816
    817 818 819 821 822 823 824 825 826 830 722
    723 724 725 726 727 728 729 752 753 831 832
    880 881
  ].freeze

  def initialize(opts = {})
    @download = opts[:download]
    @external_documents = DownloadDocuments.filter_documents(opts[:external_documents] || [])
  end

  # rubocop:disable Metrics/MethodLength
  def create_documents
    Download.transaction do
      current_documents = @external_documents.map do |external_document|
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
      (@download.documents - current_documents).each(&:destroy)

      # TODO(alex): do we still need this field? why are we setting it here?
      @download.update_attributes!(manifest_fetched_at: Time.zone.now)
    end
  end
  # rubocop:enable Metrics/MethodLength

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

  def self.filter_documents(external_documents)
    types_to_filter = IGNORED_DOC_TYPES + FIDUCIARY_DOC_TYPES + RESTRICTED_VVA_DOC_TYPES
    external_documents.reject do |document|
      type_id = document.try(:doc_type) || document.type_id
      # filter based on the type id and restricted value
      types_to_filter.include?(type_id) || document.try(:restricted)
    end
  end

  private

  def cleanup!
    files = Dir["#{@download.download_dir}/*"].reject do |filepath|
      filepath.end_with?(@download.package_filename)
    end

    FileUtils.rm files
  end
end
