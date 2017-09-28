require "vbms"
require "vva"

class Fakes::DownloadManifestJob < ActiveJob::Base
  queue_as :default

  DEMOS = {
    "DEMO1" => {
      manifest_load: 4,
      num_docs: 50,
      max_file_load: 4
    },
    "DEMO2" => {
      manifest_load: 4,
      num_docs: 100,
      max_file_load: 5
    },
    "DEMO3" => {
      manifest_load: 4,
      num_docs: 20,
      max_file_load: 4,
      error: true
    },
    "DEMO4" => {
      manifest_load: 10,
      num_docs: 400,
      max_file_load: 4
    },
    "DEMO_VBMS_ERROR" => {
      manifest_load: 1,
      num_docs: 5,
      error: true,
      error_type: "VBMS"
    },
    "DEMO_VVA_ERROR" => {
      manifest_load: 1,
      num_docs: 8,
      error: true,
      error_type: "VVA"
    },
    "DEMO_NO_DOCUMENTS" => {
      manifest_load: 1,
      num_docs: 0,
      error: true,
      error_type: "NO_DOCUMENTS"
    },
    "DEMODEFAULT" => {
      manifest_load: 4,
      num_docs: 10,
      max_file_load: 3
    }
  }.freeze

  def perform(download)
    demo = DEMOS[download.file_number] || DEMOS["DEMODEFAULT"]
    sleep_manifest_load(demo[:manifest_load])
    create_documents(download, demo[:num_docs])

    check_and_raise_errors(demo)

    download.update_attributes!(status: :pending_confirmation)
  rescue VBMS::ClientError => e
    capture_error(e, download, :vbms_connection_error)
  rescue VVA::ClientError => e
    capture_error(e, download, :vva_connection_error)
  rescue
    download.update_attributes!(status: :no_documents)
  end

  def capture_error(e, download, status)
    Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
    Raven.capture_exception(e)
    download.update_attributes!(status: status)
  end

  def check_and_raise_errors(demo)
    return unless demo[:error]
    fail VBMS::ClientError if demo[:error_type] == "VBMS"
    fail VVA::ClientError if demo[:error_type] == "VVA"
    fail "no documents" if demo[:error_type] == "NO_DOCUMENTS"
  end

  def sleep_manifest_load(wait)
    sleep(wait || 0)
  end

  def create_documents(download, number)
    (number || 0).times do |i|
      download.documents.create(
        vbms_filename: "happy-thursday-#{SecureRandom.hex}.pdf",
        type_id: Document::TYPES.keys.sample,
        document_id: "{#{SecureRandom.hex(4).upcase}-#{SecureRandom.hex(2).upcase}-#{SecureRandom.hex(2).upcase}-#{SecureRandom.hex(2).upcase}-#{SecureRandom.hex(6).upcase}}",
        mime_type: "application/pdf",
        received_at: (i * 2).days.ago,
        downloaded_from: rand(5) == 3 ? "VVA" : "VBMS"
      )
    end

    download.update_attributes!(manifest_fetched_at: Time.zone.now)
  end
end
