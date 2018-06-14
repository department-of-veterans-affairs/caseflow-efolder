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
    },
    "DEMO10" => {
      manifest_load: 1,
      num_docs: 10,
      max_file_load: 1
    },
    "DEMO100" => {
      manifest_load: 1,
      num_docs: 100,
      max_file_load: 1
    },
    "DEMO1000" => {
      manifest_load: 1,
      num_docs: 1000,
      max_file_load: 1
    }
  }.freeze

  ### Fakes v2 START
  def self.v2_fetch_documents_for(source)
    demo = DEMOS[source.file_number] || DEMOS["DEMODEFAULT"]
    return [] if !demo || demo[:num_docs] <= 0

    sleep_and_check_for_error(demo, source.name)

    (1..(demo[:num_docs] || 0)).to_a.map do |i|
      create_document(i)
    end
  end

  def self.sleep_and_check_for_error(demo, source_name)
    sleep(demo[:manifest_load] || 0)

    raise VBMS::ClientError if source_name == "VBMS" && demo[:error_type] == "VBMS"
    raise VVA::ClientError if source_name == "VVA" && demo[:error_type] == "VVA"
  end

  def self.v2_fetch_document_file(record)
    demo = DEMOS[record.file_number] || DEMOS["DEMODEFAULT"]

    sleep(rand(demo[:max_file_load] || 5))
    raise [VBMS::ClientError, VVA::ClientError].sample if demo[:error] && rand(5) == 3

    file_content(record)
  end

  def self.file_content(record)
    if record.mime_type == "application/pdf"
      IO.binread(Rails.root + "lib/pdfs/#{record.id % 5}.pdf")
    else
      IO.binread(Rails.root + "lib/tiffs/#{record.id % 5}.tiff")
    end
  end
  ### Fakes v2 END

  def self.service_type
    "Document"
  end

  def self.fetch_documents_for(download)
    list_fake_documents(download.file_number)
  end

  def self.fetch_document_file(document)
    sleep(rand(max_time))
    raise VBMS::ClientError if errors && rand(5) == 3
    raise VVA::ClientError if errors && rand(5) == 2

    if document.mime_type == "application/pdf"
      IO.binread(Rails.root + "lib/pdfs/#{document.id % 5}.pdf")
    else
      IO.binread(Rails.root + "lib/tiffs/#{document.id % 5}.tiff")
    end
  end

  # can be overridden by child classes to provide more specific error
  def self.raise_error
    raise "Could not obtain docs"
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

  # rubocop:disable Metrics/AbcSize
  def self.create_document(i)
    type = document_type

    OpenStruct.new(
      vbms_filename: "happy-thursday-#{SecureRandom.hex}.#{type[:ext]}",
      type_id: Document::TYPES.keys.sample,
      document_id: "{#{SecureRandom.hex(4).upcase}-#{SecureRandom.hex(2).upcase}-#{SecureRandom.hex(2).upcase}-#{SecureRandom.hex(2).upcase}-#{SecureRandom.hex(6).upcase}}",
      version_id: "{#{SecureRandom.hex(4).upcase}-#{SecureRandom.hex(2).upcase}-#{SecureRandom.hex(2).upcase}-#{SecureRandom.hex(2).upcase}-#{SecureRandom.hex(6).upcase}}",
      series_id: "{#{SecureRandom.hex(4).upcase}-#{SecureRandom.hex(2).upcase}-#{SecureRandom.hex(2).upcase}-#{SecureRandom.hex(2).upcase}-#{SecureRandom.hex(6).upcase}}",
      version: rand(10).to_s,
      mime_type: type[:mime_type],
      received_at: (i * 2).days.ago,
      downloaded_from: service_type
    )
  end
  # rubocop:enable Metrics/AbcSize

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
