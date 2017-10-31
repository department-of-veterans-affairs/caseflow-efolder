# rubocop:disable Metrics/ClassLength
# #626 is a task to refactor the Download model
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

  # We override the getters for veteran info so that we can fetch the values
  # from BGS if we do not have them. This lazy load allows us to avoid calling
  # any BGS endpoints if we don't need the veteran name. Specifically, the files
  # api doesn't need this information and can avoid calling BGS.
  def veteran_last_name
    fetch_veteran_info
    self[:veteran_last_name]
  end

  def veteran_first_name
    fetch_veteran_info
    self[:veteran_first_name]
  end

  def veteran_last_four_ssn
    fetch_veteran_info
    self[:veteran_last_four_ssn]
  end

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
    # We access the column names directly instead of using the rails defined get methods.
    # Since we have redefined them above, using them would trigger a fetch of veteran info.
    file_number && (!self[:veteran_last_name] || !self[:veteran_first_name])
  end

  def fetch_veteran_info
    # This fake is used in the test suite, but let's
    # also use it if we're demo-ing eFolder express.
    #
    # TODO: (alex) we should maybe be setting the fake
    # or real bgs service on an instance level, rather
    # than a class. Refactor the class method `bgs_service`
    # into an instance one.
    if !@veteran_info_fetched && missing_veteran_info?
      bgs_service = demo? ? Fakes::BGSService : Download.bgs_service

      veteran_info = bgs_service.fetch_veteran_info(file_number)

      # Calling update can result in infinite recursion if not all fields are defined
      # by BGS. Therefore we set a variable once we've fetched the data.
      @veteran_info_fetched = true
      update_attributes!(
        veteran_first_name: veteran_info["veteran_first_name"],
        veteran_last_name: veteran_info["veteran_last_name"],
        veteran_last_four_ssn: veteran_info["veteran_last_four_ssn"]
      ) if veteran_info
    end
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

    def find_or_create_by_user_and_file(user_id, file_id)
      download_scope = Download.where(user_id: user_id, file_number: file_id, from_api: true)

      download_scope.includes(:documents).last || download_scope.create!
    end
  end

  def get_cached_documents(service)
    documents.where(downloaded_from: service)
  end

  # returns <service error>, <docs>
  def fetch_vbms_manifest
    # cache manifests for 3 hours
    return nil, get_cached_documents("VBMS") if vbms_manifest_current
    error, docs = DownloadVBMSManifestJob.perform_now(self)
    [error, docs || []]
  end

  # returns <service error>, <docs>
  def fetch_vva_manifest
    # cache manifests for 3 hours
    return nil, get_cached_documents("VVA") if vva_manifest_current
    error, docs = DownloadVVAManifestJob.perform_now(self)
    [error, docs || []]
  end

  def vva_manifest_current?
    manifest_vva_fetched_at && manifest_vva_fetched_at > 3.hours.ago
  end

  def vbms_manifest_current?
    manifest_vbms_fetched_at && manifest_vbms_fetched_at > 3.hours.ago
  end

  def all_manifests_current?
    all_current = if !FeatureToggle.enabled?(:vva_service, user: user)
                    vbms_manifest_current?
                  else
                    vbms_manifest_current? && vva_manifest_current?
                  end
  end

  def force_fetch_manifest_if_expired!
    vbms_error, vbms_docs = fetch_vbms_manifest
    vva_error, vva_docs = fetch_vva_manifest

    # update object if there is an error returned
    error = vbms_error || vva_error
    if error
      update_attributes!(status: error)
      return
    end

    # only update download status at this point if we're not using
    # cached manifests
    external_documents = vbms_docs + vva_docs
    if external_documents.empty?
      update_attributes!(status: :no_documents)
    else
      update_attributes!(status: :pending_confirmation)
    end
  end

  def prepare_files_for_api!(start_download: false)
    force_fetch_manifest_if_expired!

    start_save_files_in_s3 if start_download
  end

  def start_fetch_manifest
    DownloadAllManifestJob.perform_later(self)
  end

  private

  def start_save_files_in_s3
    SaveFilesInS3Job.perform_later(self)
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
