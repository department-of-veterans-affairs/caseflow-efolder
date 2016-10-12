class Download < ActiveRecord::Base
  enum status: {
    fetching_manifest: 0,
    no_documents: 1,
    pending_confirmation: 2,
    pending_documents: 3,
    packaging_contents: 4,
    complete_success: 5,
    complete_with_errors: 6,
    vbms_connection_error: 7
  }

  TIMEOUT = 10.minutes
  HOURS_UNTIL_EXPIRY = 72

  # sort by receipt date; documents with same date ordered as sent by vbms; see
  # https://github.com/department-of-veterans-affairs/caseflow-efolder/issues/213
  has_many :documents, -> { order(received_at: :desc, id: :asc) }

  before_create do |download|
    # This fake is used in the test suite, but let's
    # also use it if we're demo-ing eFolder express.
    #
    # TODO: (alex) we should maybe be setting the fake
    # or real bgs service on an instance level, rather
    # than a class. Refactor the class method `bgs_service`
    # into an instance one.
    bgs_service = download.demo? ? Fakes::BGSService : Download.bgs_service

    if missing_veteran_info?
      veteran_info = bgs_service.fetch_veteran_info(download.file_number)
      if veteran_info
        download.veteran_first_name = veteran_info["veteran_first_name"]
        download.veteran_last_name = veteran_info["veteran_last_name"]
        download.veteran_last_four_ssn = veteran_info["veteran_last_four_ssn"]
      end
    end
  end

  def veteran_name
    "#{veteran_first_name} #{veteran_last_name}" if veteran_last_name
  end

  def self.active
    where(created_at: Download::HOURS_UNTIL_EXPIRY.hours.ago..Time.zone.now)
  end

  def demo?
    file_number =~ /DEMO/
  end

  def missing_veteran_info?
    file_number && (!veteran_first_name || !veteran_last_name || !veteran_last_four_ssn)
  end

  def time_to_fetch_manifest
    manifest_fetched_at - created_at
  end

  def time_to_fetch_files
    return nil unless started_at && completed_at

    completed_at - started_at
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
    !Download.bgs_service.fetch_veteran_info(file_number).nil?
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
    "#{veteran_last_name}, #{veteran_first_name} - #{veteran_last_four_ssn}.zip"
  end

  def reset!
    Download.transaction do
      update_attributes!(status: :pending_documents)
      documents.update_all(filepath: nil, download_status: 0)
    end
  end

  def complete!
    update_attributes(
      completed_at: Time.zone.now,
      status: errors? ? :complete_with_errors : :complete_success
    )
  end

  def user_id_string
    "#{user_id} (Station #{user_station_id})"
  end

  def self.downloads_by_user(downloads:)
    downloads.each_with_object({}) do |download, result|
      result[download.user_id_string] ||= 0
      result[download.user_id_string] += 1
    end
  end

  def self.top_users(downloads:)
    users = downloads_by_user(downloads: downloads)
    sorted = users.sort_by { |_k, v| -v }
    sorted.map { |values| { id: values[0], count: values[1] } }.first(3)
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
