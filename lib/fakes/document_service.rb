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
      num_docs: 0
    },
    "DEMODEFAULT" => {
      manifest_load: 4,
      num_docs: 10,
      max_file_load: 3
    }
  }.freeze

  def self.service_type
    "Document"
  end

  def self.fetch_documents_for(download)
    list_fake_documents(download.file_number)
  end

  def self.fetch_document_file(document)
    sleep(rand(max_time))
    fail VBMS::ClientError if errors && rand(5) == 3
    fail VVA::ClientError if errors && rand(5) == 2

    if document.mime_type == "application/pdf"
      IO.binread(Rails.root + "lib/pdfs/#{document.id % 5}.pdf")
    else
      IO.binread(Rails.root + "lib/tiffs/#{document.id % 5}.tiff")
    end
  end

  # can be overridden by child classes to provide more specific error
  def self.raise_error
    fail "Could not obtain docs"
  end

  def self.check_and_raise_errors(demo)
    return unless demo[:error]
    raise_error if demo[:error_type] == service_type
  end

  def self.sleep_manifest_load(wait)
    sleep(wait || 0)
  end

  # Randomly send a pdf or tiff
  def self.document_type
    return { ext: "pdf", mime_type: "application/pdf" } if rand(2) == 1
    { ext: "tiff", mime_type: "image/tiff" }
  end

  def self.create_document(i)
    type = document_type

    OpenStruct.new(
      vbms_filename: "happy-thursday-#{SecureRandom.hex}.#{type[:ext]}",
      type_id: Document::TYPES.keys.sample,
      document_id: "{#{SecureRandom.hex(4).upcase}-#{SecureRandom.hex(2).upcase}-#{SecureRandom.hex(2).upcase}-#{SecureRandom.hex(2).upcase}-#{SecureRandom.hex(6).upcase}}",
      mime_type: type[:mime_type],
      received_at: (i * 2).days.ago,
      downloaded_from: service_type
    )
  end

  def self.list_fake_documents(file_number)
    demo = DEMOS[file_number]
    demo = DEMOS["DEMODEFAULT"] if !demo && file_number =~ /^DEMO/
    return [] if !demo || demo[:num_docs] <= 0

    sleep_manifest_load(demo[:manifest_load])
    check_and_raise_errors(demo)

    (0..(demo[:num_docs] || 0)).to_a.map do |i|
      create_document(i)
    end
  end
end
