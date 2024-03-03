require "vbms"
require "vva"

module Fakes
  class DocumentService
    cattr_accessor :errors, :max_time

    DEMOS = {
      "DEMO1" => { manifest_load: 4, num_docs: 50, max_file_load: 4 },
      "DEMO2" => { manifest_load: 4, num_docs: 100, max_file_load: 5 },
      "DEMO3" => { manifest_load: 4, num_docs: 20, max_file_load: 4, error: true },
      "DEMO4" => { manifest_load: 10, num_docs: 400, max_file_load: 4 },
      "DEMO_VBMS_ERROR" => { manifest_load: 1, num_docs: 5, error: true, error_type: "VBMS" },
      "DEMO_VVA_ERROR" => { manifest_load: 1, num_docs: 8, error: true, error_type: "VVA" },
      "DEMO_NO_DOCUMENTS" => { manifest_load: 1, num_docs: 0 },
      "DEMODEFAULT" => { manifest_load: 4, num_docs: 10, max_file_load: 3 },
      "DEMOFAST" => { manifest_load: 0, num_docs: 10, max_file_load: 1 }
    }.freeze

    Document = Struct.new(
      :vbms_filename, :type_id, :document_id, :version_id, :series_id,
      :version, :mime_type, :received_at, :upload_date, :downloaded_from
    )

    class << self
      def v2_fetch_documents_for(file_number)
        demo = DEMOS[file_number] || DEMOS["DEMODEFAULT"]
        return [] if demo[:num_docs].to_i <= 0

        sleep_and_check_for_error(demo, file_number)

        (1..(demo[:num_docs] || 0)).map { |i| create_document(i) }
      end

      def fetch_delta_documents_for(file_number, _begin_date)
        v2_fetch_documents_for(file_number)
      end

      def v2_fetch_document_file(record)
        demo = DEMOS[record.file_number] || DEMOS["DEMODEFAULT"]

        sleep(rand(demo[:max_file_load] || 5))
        raise [VBMS::ClientError, VVA::ClientError].sample if demo[:error] && rand(5) == 3

        file_content(record)
      end

      def fetch_documents_for(download)
        list_fake_documents(download.file_number)
      end

      def fetch_document_file(document)
        sleep(rand(max_time))
        raise VBMS::ClientError if errors && rand(5) == 3
        raise VVA::ClientError if errors && rand(5) == 2

        document_content(document)
      end

      private

      def sleep_and_check_for_error(demo, source_name)
        sleep(demo[:manifest_load] || 0)

        raise VBMS::ClientError if source_name == "VBMS" && demo[:error_type] == "VBMS"
        raise VVA::ClientError if source_name == "VVA" && demo[:error_type] == "VVA"
      end

      def file_content(record)
        filename = document_filename(record)
        IO.binread(filename)
      end

      def document_filename(record)
        file_type = record.mime_type == "application/pdf" ? "pdf" : "tiff"
        Rails.root.join("lib", file_type + "s", "#{record.id % 5}.#{file_type}")
      end

      def create_document(index)
        document_type = rand(2).zero? ? "pdf" : "tiff"

        Document.new(
          "happy-thursday-#{SecureRandom.hex}.#{document_type}",
          (11..20).to_a.sample,
          generate_document_id,
          generate_document_id,
          generate_document_id,
          rand(10).to_s,
          document_type == "pdf" ? "application/pdf" : "image/tiff",
          index * 2.days.ago,
          index.days.ago,
          "Document"
        )
      end

      def generate_document_id
        SecureRandom.uuid.upcase
      end

      def list_fake_documents(file_number)
        demo = DEMOS[file_number] || DEMOS["DEMODEFAULT"]
        return [] if invalid_demo?(demo)

        simulate_manifest_load(demo)

        raise_client_error_if_needed(demo)

        generate_fake_documents(demo[:num_docs].to_i)
      end

      def invalid_demo?(demo)
        demo[:num_docs].to_i <= 0
      end

      def simulate_manifest_load(demo)
        sleep(demo[:manifest_load] || 0)
      end

      def raise_client_error_if_needed(demo)
        raise VBMS::ClientError if demo[:error] && rand(5) == 3
      end

      def generate_fake_documents(num_docs)
        (0..num_docs).map { |i| create_document(i) }
      end
    end
  end
end
