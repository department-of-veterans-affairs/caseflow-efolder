require "fileutils"
require "zip"
require "rails_helper"

describe DownloadDocuments do
  before do
    Download.bgs_service = Fakes::BGSService

    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:download) do
    Download.create(
      file_number: "21012",
      veteran_first_name: "George",
      veteran_last_name: "Washington"
    )
  end

  let(:vbms_documents) do
    [
      OpenStruct.new(document_id: "1", filename: "filename.pdf", doc_type: "123",
                     source: "SRC", received_at: Time.zone.now, type_id: "123",
                     mime_type: "application/pdf", type_description: "VA 9 Appeal to Board of Appeals"),
      OpenStruct.new(document_id: "2", received_at: 1.hour.ago)
    ]
  end

  let(:download_documents) do
    DownloadDocuments.new(download: download, vbms_documents: vbms_documents, s3: Caseflow::Fakes::S3Service)
  end

  context "#save_document_file" do
    let(:document) do
      download.documents.build(
        document_id: "{3333-3333}",
        received_at: Time.utc(2015, 9, 6, 1, 0, 0),
        type_id: "825",
        mime_type: "application/pdf"
      )
    end

    let(:txt_document) do
      download.documents.build(
        document_id: "{4444-4444}",
        received_at: Time.utc(2016, 2, 2, 1, 0, 0),
        type_id: "825",
        mime_type: "text/plain"
      )
    end

    before do
      # clean files
      FileUtils.rm_rf(Rails.application.config.download_filepath)
    end

    it "creates a file in the correct directory and returns filename" do
      file_contents = IO.binread(Rails.root + "spec/support/test.pdf")
      filename = download_documents.save_document_file(document, file_contents, 3)
      expected_filepath = Rails.root + "tmp/files/#{download.id}/00040-VA 21-0166 VA Letter to Beneficiary-20150906-3333-3333.pdf"
      expect(File.exist?(expected_filepath)).to be_truthy
      expect(filename).to eq(expected_filepath.to_s)
    end

    it "handles non-pdf files correctly" do
      filename = download_documents.save_document_file(txt_document, "Howdy", 3)
      expect(IO.read(filename)).to eq("Howdy")
    end
  end

  context "#create_documents" do
    before do
      download_documents.create_documents
    end

    it "persists info about each document and sets manifest_fetched_at" do
      expect(Document.count).to equal(2)

      document = Document.first
      expect(document.document_id).to eq("1")
      expect(document.filename).to eq("VA 9 Appeal to Board of Appeals-20150101-1.pdf")
      expect(document.type_id).to eq("123")
      expect(document.source).to eq("SRC")
      expect(document.mime_type).to eq("application/pdf")
      expect(document.type_description).to eq "VA 9 Appeal to Board of Appeals"
      expect(document).to be_pending

      expect(download.manifest_fetched_at).to eq(Time.zone.now)
    end
  end

  context "#download_contents" do
    let(:file) { IO.binread(Rails.root + "spec/support/test.pdf") }

    before do
      # clean files
      FileUtils.rm_rf(Rails.application.config.download_filepath)
      Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
    end

    after { Timecop.return }

    context "when one file errors" do
      before do
        allow(VBMSService).to receive(:fetch_document_file) do |document|
          fail VBMS::ClientError, "Failure" if document.document_id != "1"
          file
        end

        download_documents.create_documents
        download_documents.download_contents
      end

      it "saves download state for each document" do
        successful_document = Document.first
        expect(successful_document).to be_success
        expect(successful_document.filepath).to eq((Rails.root + "tmp/files/#{download.id}/00010-VA 9 Appeal to Board of Appeals-20150101-1.pdf").to_s)
        expect(successful_document.started_at).to eq(Time.zone.now)
        expect(successful_document.completed_at).to eq(Time.zone.now)
        expect(successful_document.error_message).to eq nil

        errored_document = Document.last
        expect(errored_document).to be_failed
        expect(errored_document.started_at).to eq(Time.zone.now)
        expect(errored_document.error_message).to match(/Failure/)
      end

      it "stores successful document in s3" do
        successful_document = Document.first
        s3 = Caseflow::Fakes::S3Service
        expect(s3.files[successful_document.s3_filename]).to eq(IO.binread(Rails.root + "spec/support/test.pdf"))
      end
    end

    context "when two files have the same name" do
      before do
        allow(VBMSService).to receive(:fetch_document_file) { |_document| file }
        download_documents.create_documents
        download_documents.download_contents
      end

      let(:vbms_documents) do
        [
          OpenStruct.new(document_id: "1", filename: "filename.pdf", doc_type: "123",
                         source: "SRC", received_at: Time.zone.now,
                         mime_type: "application/pdf"),
          OpenStruct.new(document_id: "1", filename: "filename.pdf", doc_type: "123",
                         source: "SRC", received_at: Time.zone.now,
                         mime_type: "application/pdf")
        ]
      end

      it "saves download state for each document" do
        expect(Dir[Rails.root + "tmp/files/#{download.id}/*"].size).to eq(2)

        download.documents.each_with_index do |document, i|
          expect(document).to be_success
          expect(document.filepath).to eq((Rails.root + "tmp/files/#{download.id}/000#{i + 1}0-VA 21-4185 Report of Income from Property or Business-20150101-1.pdf").to_s)
          expect(File.exist?(document.filepath)).to be_truthy
        end
      end
    end
  end

  context "#download_and_package" do
    let(:file) { IO.binread(Rails.root + "spec/support/test.pdf") }
    let(:vbms_documents) do
      [
        OpenStruct.new(document_id: "1", filename: "keep-stamping.pdf", doc_type: "123",
                       source: "SRC", received_at: Time.zone.now,
                       mime_type: "application/pdf")
      ]
    end

    before do
      # clean files
      FileUtils.rm_rf(Rails.application.config.download_filepath)

      allow(VBMSService).to receive(:fetch_document_file) do |document|
        fail VBMS::ClientError if document.document_id != "1"
        file
      end
    end

    it "exits on document stale record error" do
      expect(download_documents).to receive(:before_document_download) do |document|
        Document.find(document.id).update_attributes!(started_at: Time.zone.now)
      end

      download_documents.create_documents
      download_documents.download_and_package
      expect(File.exist?(Rails.root + "tmp/files/#{download.id}/#{download.package_filename}")).to be_falsey
    end

    it "exits on download stale record error when packaging" do
      expect(download_documents).to receive(:before_package_contents) do |_|
        Download.find(download.id).update_attributes!(status: :packaging_contents)
      end

      download_documents.create_documents
      download_documents.download_and_package
      expect(File.exist?(Rails.root + "tmp/files/#{download.id}/#{download.package_filename}")).to be_falsey
    end

    it "packages files into zip and completes" do
      download_documents.create_documents
      download_documents.download_and_package

      download_dir = "tmp/files/#{download.id}"
      zip_path = Rails.root + "#{download_dir}/#{download.package_filename}"
      Zip::File.open(zip_path) do |zip_file|
        expect(zip_file.glob("00010-VA 21-4185 Report of Income from Property or Business-20150101-1.pdf").first).to_not be_nil
      end

      # Test that other files are cleared out
      expect(Dir["tmp/files/#{download.id}/*"].length).to eq(1)

      expect(download).to be_complete_success
      expect(download.started_at).to eq(Time.zone.now)
      expect(download.completed_at).to eq(Time.zone.now)
      expect(download.zipfile_size).to eq(File.size(zip_path))
    end

    it "works even if zip exists" do
      download_documents.create_documents
      download_documents.download_and_package
      expect { download_documents.download_and_package }.to_not raise_error
    end

    context "when one document errors" do
      let(:vbms_documents) do
        [
          OpenStruct.new(document_id: "1", filename: "filename.pdf", doc_type: "123",
                         source: "SRC", received_at: Time.zone.now,
                         mime_type: "application/pdf"),
          OpenStruct.new(document_id: "2")
        ]
      end

      it "sets status to complete_with_errors" do
        download_documents.create_documents
        download_documents.download_and_package

        expect(download).to be_complete_with_errors
      end
    end

    context "when files are deleted from the file system" do
      before do
        expect(download_documents).to receive(:before_package_contents) do
          Document.all.each do |document|
            FileUtils.rm_rf(document.filepath)
          end
        end
      end

      it "retrieves them from s3" do
        download_documents.create_documents
        download_documents.download_and_package

        Zip::File.open(Rails.root + "tmp/files/#{download.id}/#{download.package_filename}") do |zip_file|
          expect(zip_file.glob("00010-VA 21-4185 Report of Income from Property or Business-20150101-1.pdf").first).to_not be_nil
        end
      end
    end

    context "when some vbms files aren't supported" do
      let(:vbms_documents) do
        [
          OpenStruct.new(document_id: "1", doc_type: "352"),
          OpenStruct.new(document_id: "2", doc_type: "999981"),
          OpenStruct.new(document_id: "3", doc_type: "600"),
          OpenStruct.new(document_id: "4", doc_type: "542")
        ]
      end

      it "filters unsupported types" do
        download_documents.create_documents
        expect(download.documents.count).to eq(1)
        expect(download.documents[0].document_id).to eq("1")
      end
    end
  end
end
