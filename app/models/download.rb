class Download < ActiveRecord::Base
  enum status: {
    fetching_manifest: 0,
    no_documents: 1,
    pending_confirmation: 2,
    pending_documents: 3,
    packaging_contents: 4,
    complete_success: 5,
    complete_with_errors: 6,
    vbms_connection_error: 7,
    vva_connection_error: 8
  }

  TIMEOUT = 10.minutes
  HOURS_UNTIL_EXPIRY = 72

  # sort by receipt date; documents with same date ordered as sent by vbms; see
  # https://github.com/department-of-veterans-affairs/caseflow-efolder/issues/213
  has_many :documents, -> { order(received_at: :desc, id: :asc) }
  has_many :searches
  belongs_to :user

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

  # Wait for the record to be committed to the DB and only then start the Sidekiq job
  # Here is the issue: https://github.com/mperham/sidekiq/issues/322
  after_commit :start_fetch_manifest, on: :create

  def veteran_name
    "#{veteran_first_name} #{veteran_last_name}" if veteran_last_name
  end

  def self.active
    where(created_at: Download::HOURS_UNTIL_EXPIRY.hours.ago..Time.zone.now + 5.seconds)
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

  def download_dir
    return @download_dir if @download_dir

    basepath = Rails.application.config.download_filepath
    Dir.mkdir(basepath) unless File.exist?(basepath)

    @download_dir = File.join(basepath, id.to_s)
    Dir.mkdir(@download_dir) unless File.exist?(@download_dir)

    @download_dir
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
      documents.update_all(filepath: nil, download_status: 0, completed_at: nil)
    end
  end

  def complete!(zipfile_size)
    update_attributes(
      zipfile_size: zipfile_size,
      completed_at: Time.zone.now,
      status: errors? ? :complete_with_errors : :complete_success
    )
  end

  def css_id_string
    return "Unknown" unless user
    "(#{user.css_id} - Station #{user.station_id})"
  end

  def expiration_day
    started_at ? (started_at + HOURS_UNTIL_EXPIRY.hours).strftime("%m/%d") : nil
  end

  def number_of_documents
    documents.count
  end

  def self.downloads_by_user(downloads:)
    downloads.each_with_object({}) do |download, result|
      next unless download.user
      result[download.css_id_string] ||= {}
      result[download.css_id_string][:email] ||= download.user.email || User::NO_EMAIL
      result[download.css_id_string][:count] ||= 0
      result[download.css_id_string][:count] += 1
    end
  end

  def self.top_users(downloads:)
    users = downloads_by_user(downloads: downloads)
    sorted = users.sort_by { |_k, v| -v[:count] }
    sorted.map { |values| { id: values[1][:email] + " " + values[0], count: values[1][:count] } }.first(3)
  end

  class << self
    def bgs_service=(service)
      if Rails.env.test?
        @bgs_service = service
      else
        Thread.current[:download_bgs_service] = service
      end
    end

    def bgs_service
      if Rails.env.test?
        @bgs_service
      else
        Thread.current[:download_bgs_service]
      end
    end
  end

  private

  def start_fetch_manifest
    demo? ? DemoGetDownloadManifestJob.perform_later(self) : GetDownloadManifestJob.perform_later(self)
  end

  def calculate_estimated_to_complete_at
    return nil unless pending_documents?

    current_doc = documents.where(completed_at: nil).where.not(started_at: nil).first
    return nil unless current_doc

    documents_left = documents.where(completed_at: nil).count

    historical_rate = Document.historical_average_download_rate
    return nil unless historical_rate
    current_doc.started_at + (historical_rate * documents_left)
  end
end
