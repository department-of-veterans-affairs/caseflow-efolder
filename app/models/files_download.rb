class FilesDownload < ActiveRecord::Base
  belongs_to :user
  belongs_to :manifest
  has_many :sources, through: :manifest
  has_many :records, through: :manifest

  validates :manifest, :user, presence: true

  enum status: {
    initialized: 0,
    pending: 1,
    finished: 2,
    failed: 3
  }

  def start!
    return if current? || pending?
    update(status: :pending)
    V2::PackageFilesJob.perform_later(self)
  end

  private

  def current?
    finished? && fetched_files_at && fetched_files_at > 3.days.ago
  end
end
