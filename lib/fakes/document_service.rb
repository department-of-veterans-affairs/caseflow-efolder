require "vbms"
require "vva"

class Fakes::DocumentService
  cattr_accessor :errors, :max_time

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
    },
    "DEMODEFAULT" => {
      manifest_load: 4,
      num_docs: 10,
      max_file_load: 3
    }
  }.freeze

  def self.fetch_documents_for(download)
    demo = DEMOS[download.file_number] || DEMOS["DEMODEFAULT"]
    self.sleep_manifest_load(demo[:manifest_load])

    self.check_and_raise_errors(demo)
    docs = self.create_documents(download, demo[:num_docs])
    return docs
  end

  def self.fetch_document_file(document)
    sleep(rand(max_time))
    fail VBMS::ClientError if errors && rand(5) == 3
    fail VVA::ClientError if errors && rand(5) == 2

    IO.binread(Rails.root + "lib/pdfs/#{document.id % 5}.pdf")
  end

  def self.check_and_raise_errors(demo)
    return unless demo[:error]
    fail VBMS::ClientError if demo[:error_type] == "VBMS"
    fail VVA::ClientError if demo[:error_type] == "VVA"
  end

  def self.sleep_manifest_load(wait)
    sleep(wait || 0)
  end

  def self.create_documents(download, number)
    docs = []
    (number || 0).times do |i|
      doc = download.documents.create(
        vbms_filename: "happy-thursday-#{SecureRandom.hex}.pdf",
        type_id: Document::TYPES.keys.sample,
        document_id: "{#{SecureRandom.hex(4).upcase}-#{SecureRandom.hex(2).upcase}-#{SecureRandom.hex(2).upcase}-#{SecureRandom.hex(2).upcase}-#{SecureRandom.hex(6).upcase}}",
        mime_type: "application/pdf",
        received_at: (i * 2).days.ago,
        downloaded_from: rand(5) == 3 ? "VVA" : "VBMS"
      )
      docs.push(doc)
    end
    return docs
  end
end
