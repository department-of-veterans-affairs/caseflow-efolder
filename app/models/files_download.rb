class FilesDownload < ActiveRecord::Base
  belongs_to :user
  belongs_to :manifest

  validates :manifest, :user, presence: true

  def start!
    update(requested_zip_at: Time.zone.now)
    manifest.download_and_package_files!
  end
end
