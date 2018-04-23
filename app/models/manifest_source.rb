class ManifestSource < ApplicationRecord
  include ApplicationHelper

  enum status: {
    initialized: 0,
    pending: 1,
    success: 2,
    failed: 3
  }

  belongs_to :manifest
  has_many :records, dependent: :destroy

  validates :manifest, :name, presence: true
  validates :manifest, uniqueness: { scope: :name }
  validates :name, inclusion: { in: %w[VBMS VVA] }

  delegate :file_number, to: :manifest

  def start!
    s = Redis::Semaphore.new("download_manifest_source_#{id}".to_s, url: Rails.application.secrets.redis_url)
    s.lock do
      return if current? || pending?
      update(status: :pending)
    end

    V2::DownloadManifestJob.perform_later(self, ui_user?)
  end

  def service
    case name
    when "VBMS"
      VBMSService
    when "VVA"
      VVAService
    end
  end

  def expiry_hours
    ui_user? ? Manifest::UI_HOURS_UNTIL_EXPIRY : Manifest::API_HOURS_UNTIL_EXPIRY
  end

  def current?
    success? && fetched_at && fetched_at > expiry_hours.hours.ago
  end
end
