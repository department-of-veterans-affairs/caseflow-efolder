class DemoGetDownloadManifestJob < ActiveJob::Base
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
      num_docs: 100,
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
    "DEMO_NO_DOCUMENTS" => {
      manifest_load: 1,
      num_docs: 0,
      error: true,
      error_type: "NO_DOCUMENTS"
    },
    "DEMO_NOT_FOUND" => {
      manifest_load: 1,
      num_docs: 6,
      error: true,
      error_type: "NOT_FOUND"
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
    Rails.logger.info "#{e.message}\n#{e.backtrace.join("\n")}"
    Raven.capture_exception(e)
    download.update_attributes!(status: :vbms_connection_error)
  rescue
    if demo[:error_type] == "NOT_FOUND"
      download.update_attributes!(status: :download_not_found)
    elsif demo[:error_type] == "NO_DOCUMENTS"
      download.update_attributes!(status: :no_documents)
    end
  end

  def check_and_raise_errors(demo)
    return unless demo[:error]
    fail VBMS::ClientError if demo[:error_type] == "VBMS"
    fail "no documents" if demo[:error_type] == "NO_DOCUMENTS"
    fail "not found" if demo[:error_type] == "NOT_FOUND"
  end

  def sleep_manifest_load(wait)
    sleep(wait || 0)
  end

  def create_documents(download, number)
    (number || 0).times do |i|
      download.documents.create(
        vbms_filename: "happy-thursday-#{SecureRandom.hex}.txt",
        doc_type: Document::TYPES.keys.sample,
        document_id: "{#{SecureRandom.hex(4).upcase}-#{SecureRandom.hex(2).upcase}-#{SecureRandom.hex(2).upcase}-#{SecureRandom.hex(2).upcase}-#{SecureRandom.hex(6).upcase}}",
        mime_type: "text/plain",
        received_at: (i * 2).days.ago
      )
    end

    download.update_attributes!(manifest_fetched_at: Time.zone.now)
  end
end
