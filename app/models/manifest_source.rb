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
    return if current? || processing?

    update(status: :pending)

    V2::DownloadManifestJob.perform_later(self, RequestStore[:current_user])
  rescue StandardError
    update(status: :initialized)

    raise
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

  def processing?
    pending? && fetched_at && fetched_at > 24.hours.ago
  end
end
