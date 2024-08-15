require "action_view"

class Manifest < ApplicationRecord
  include ActionView::Helpers::DateHelper

  has_many :sources, class_name: "ManifestSource", dependent: :destroy
  has_many :files_downloads, dependent: :destroy
  has_many :users, through: :files_downloads

  # Sort by receipt date; documents with same date ordered as sent by vbms
  has_many :records, -> { order(received_at: :desc, id: :asc) }, through: :sources

  validates :file_number, presence: true

  enum fetched_files_status: {
    initialized: 0,
    pending: 1,
    finished: 2,
    failed: 3
  }

  UI_HOURS_UNTIL_EXPIRY = 72
  API_HOURS_UNTIL_EXPIRY = 3

  SECONDS_TO_AUTO_UNLOCK = 5

  # single user for authorization on an instance - not persisted
  attr_accessor :user

  def start!
    # Reset stale manifests.
    update!(fetched_files_status: :initialized) if ready_for_refresh?

    if FeatureToggle.enabled?(:check_user_sensitivity)
      if sensitivity_checker.sensitivity_levels_compatible?(
        user: user,
        veteran_file_number: file_number
      )
        vbms_source.start!
      else
        raise BGS::SensitivityLevelCheckFailure.new, "Unauthorized"
      end
    else
      vbms_source.start!
    end

    vva_source.start! unless FeatureToggle.enabled?(:skip_vva)
  end

  def download_and_package_files!
    s = Redis::Semaphore.new("package_files_#{id}".to_s,
                             url: Rails.application.secrets.redis_url_cache,
                             expiration: SECONDS_TO_AUTO_UNLOCK)
    s.lock(SECONDS_TO_AUTO_UNLOCK) do
      return if pending?

      update(fetched_files_status: :pending)
    end

    begin
      reset_records
      V2::PackageFilesJob.perform_later(self)
    rescue StandardError
      update(fetched_files_status: :initialized)

      raise
    end
  end

  # ready_for_refresh? we want to refresh the manifest after 72 hours regardless of the state
  def ready_for_refresh?
    !initialized? && fetched_files_at && fetched_files_at < UI_HOURS_UNTIL_EXPIRY.hours.ago
  end

  def completed?
    finished? || failed?
  end

  def recently_downloaded_files?
    finished? && fetched_files_at && fetched_files_at > 3.hours.ago
  end

  def reset_records
    records.update_all(status: 0)
  end

  def vbms_source
    with_lock { sources.find_or_create_by(name: "VBMS") }
  end

  def vva_source
    with_lock { sources.find_or_create_by(name: "VVA") }
  end

  def number_successful_documents
    records.select(&:success?).size
  end

  def time_to_complete
    distance_of_time_in_words(Time.zone.now, Time.zone.now + seconds_left, include_seconds: true)
  end

  def seconds_left
    records.select(&:initialized?).count * Record::AVERAGE_DOWNLOAD_TIME_IN_SECONDS
  end

  # Zip expiration date will be determined on per user basis
  def zip_expiration_date
    requested_zip_at ? (requested_zip_at + UI_HOURS_UNTIL_EXPIRY.hours).strftime("%m/%d") : nil
  end

  def number_failed_documents
    records.select(&:failed?).size
  end

  def s3_filename
    "#{id}-manifest.zip"
  end

  def package_filename
    "#{veteran_last_name}, #{veteran_first_name} - #{veteran_last_four_ssn}.zip"
  end

  def stream_zip!
    S3Service.stream_content(s3_filename)
  end

  # If we do not yet have the veteran info saved in Caseflow's DB, then
  # we want to fetch it from BGS, save it to the DB, then return it
  %w[veteran_first_name veteran_last_name veteran_last_four_ssn].each do |name|
    define_method(name) do
      self[name] || begin
        update_veteran_info
        self[name]
      end
    end
  end

  def veteran
    @veteran ||= fetch_veteran
  end

  def self.find_or_create_by_user(user:, file_number:)
    manifest = nil
    begin
      Manifest.transaction(requires_new: true) do
        manifest = Manifest.find_or_create_by!(file_number: file_number)
      end
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    begin
      FilesDownload.transaction(requires_new: true) do
        manifest.files_downloads.find_or_create_by!(user: user)
      end
    rescue ActiveRecord::RecordNotUnique
      retry
    end
    manifest.user = user
    manifest
  end

  private

  def fetch_veteran
    Veteran.new(user: user, file_number: file_number).load_bgs_record!
  end

  def file_download
    files_downloads.find_by(user: RequestStore[:current_user])
  end

  def requested_zip_at
    file_download ? file_download.requested_zip_at : nil
  end

  def update_veteran_info
    return unless veteran
    update(veteran_first_name: veteran.first_name || "",
           veteran_last_name: veteran.last_name || "",
           veteran_last_four_ssn: veteran.last_four_ssn || "")
  end

  def sensitivity_checker
    @sensitivity_checker ||= SensitivityChecker.new
  end
end
