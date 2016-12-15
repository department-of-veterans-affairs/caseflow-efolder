##
# Search represents any instance of a user searching for a
# veteran's eFolder, successfully or unsuccessfully. If successful,
# it performs logic required to initialize the subsequent download.
#
class Search < ActiveRecord::Base
  belongs_to :download

  enum status: {
    download_created: 0,
    download_found: 1,
    veteran_not_found: 2,
    access_denied: 3
  }

  def perform!
    return true if match_existing_download

    self.download = download_scope.new

    return false unless validate!

    transaction do
      update_attributes!(status: :download_created)
      download.save!
    end
    start_fetch_manifest
    true
  end

  def sanitized_file_number
    (file_number || "").strip
  end

  def user=(user)
    self.user_id = user.id
    self.user_station_id = user.station_id
    self.email = user.email
  end

  private

  def download_scope
    Download.active.where(
      file_number: sanitized_file_number,
      user_id: user_id,
      user_station_id: user_station_id
    ).where.not(status: [1, 7])
  end

  def match_existing_download
    return false unless (self.download = download_scope.first)

    update_attributes!(status: :download_found)
    true
  end

  def validate!
    if download.demo?
      return true

    elsif !download.case_exists?
      update_attributes!(status: :veteran_not_found)
      return false

    elsif !download.can_access?
      update_attributes!(status: :access_denied)
      return false
    end

    true
  end

  def start_fetch_manifest
    if download.demo?
      DemoGetDownloadManifestJob.perform_later(download)
    else
      GetDownloadManifestJob.perform_later(download)
    end
  end
end
