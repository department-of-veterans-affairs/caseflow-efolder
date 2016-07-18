class Download < ActiveRecord::Base
  enum status: {
    fetching_manifest: 0,
    no_documents: 1,
    pending_confirmation: 2,
    pending_documents: 3,
    packaging_contents: 4,
    complete_success: 5,
    complete_with_errors: 6
  }

  TIMEOUT = 10.minutes

  has_many :documents, -> { order(:id) }

  after_initialize do |download|
    if download.file_number
      download.veteran_name ||= download.demo? ? "TEST" : Download.bgs_service.fetch_veteran_name(download.file_number)
    end
  end

  def demo?
    file_number =~ /DEMO/
  end

  def stalled?
    pending_documents? && ((Time.zone.now - TIMEOUT) > updated_at)
  end

  def errors?
    documents.where(download_status: 2).any?
  end

  def complete?
    complete_success? || complete_with_errors?
  end

  def estimated_to_complete_at
    @estimated_to_complete_at ||= calculate_estimated_to_complete_at
  end

  def case_exists?
    !Download.bgs_service.fetch_veteran_name(file_number).nil?
  rescue
    false
  end

  def can_access?
    Download.bgs_service.check_sensitivity(file_number)
  end

  def confirmed?
    pending_documents? || complete?
  end

  def complete_documents
    documents.select { |d| !d.pending? }
  end

  def progress_percentage
    if fetching_manifest?
      20
    elsif pending_documents?
      20 + ((complete_documents.count + 1.0) / (documents.count + 1.0) * 80).round
    else
      100
    end
  end

  def s3_filename
    "#{id}-download.zip"
  end

  def package_filename
    "#{veteran_name.gsub(/\s*/, '').downcase}-#{created_at.to_formatted_s(:filename)}.zip"
  end

  class << self
    attr_writer :bgs_service

    def bgs_service
      @bgs_service ||= BGSService
    end
  end

  private

  def calculate_estimated_to_complete_at
    return nil unless pending_documents?

    current_doc = documents.where(completed_at: nil).where.not(started_at: nil).first
    return nil unless current_doc

    completed_durations = documents.where.not(completed_at: nil).map do |document|
      document.completed_at - document.started_at
    end
    return nil if completed_durations.empty?

    documents_left = documents.where(completed_at: nil).count

    current_doc.started_at + (completed_durations.inject(:+) / completed_durations.count * documents_left)
  end
end
