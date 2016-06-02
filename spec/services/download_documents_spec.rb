require "fileutils"
require "zip"

describe DownloadDocuments do
  before do
    Download.delete_all
    Document.delete_all
  end

  let(:download) { Download.create!(file_number: "21012") }

  let(:vbms_documents) do
    [
      VBMS::Responses::Document.new(document_id: "1", filename: "filename.pdf", doc_type: "123",
                                    source: "SRC", received_at: Time.zone.now,
                                    mime_type: "application/pdf"),
      VBMS::Responses::Document.new(document_id: "2")
    ]
  end

  let(:download_documents) do
    DownloadDocuments.new(download: download, vbms_documents: vbms_documents)
  end

  context "#save_document_file" do
    let(:document) do
      download.documents.build(document_id: "3", vbms_filename: "happyfile.pdf", mime_type: "application/pdf")
    end

    before do
      # clean files
      FileUtils.rm_rf(Rails.application.config.download_filepath)
    end

    it "creates a file in the correct directory and returns filename" do
      filename = download_documents.save_document_file(document, "hi", 3)
      expect(File.exist?(Rails.root + "tmp/files/#{download.id}/3-happyfile.pdf")).to be_truthy
      expect(filename).to eq((Rails.root + "tmp/files/#{download.id}/3-happyfile.pdf").to_s)
    end
  end

  context "#create_documents" do
    before do
      download_documents.create_documents
    end

    it "persists info about each document" do
      expect(Document.count).to equal(2)

      document = Document.first
      expect(document.document_id).to eq("1")
      expect(document.filename).to eq("filename.pdf")
      expect(document.doc_type).to eq("123")
      expect(document.source).to eq("SRC")
      expect(document.mime_type).to eq("application/pdf")
      expect(document).to be_pending
    end
  end

  context "#download_contents" do
    let(:file) { "file content" }

    before do
      # clean files
      FileUtils.rm_rf(Rails.application.config.download_filepath)
    end

    context "when one file errors" do
      before do
        allow(VBMSService).to receive(:fetch_document_file) do |document|
          fail VBMS::ClientError if document.document_id != "1"
          file
        end

        download_documents.create_documents
        download_documents.download_contents
      end

      it "saves download state for each document" do
        successful_document = Document.first
        expect(successful_document).to be_success
        expect(successful_document.filepath).to eq((Rails.root + "tmp/files/#{download.id}/0-filename.pdf").to_s)

        errored_document = Document.last
        expect(errored_document).to be_failed
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
          VBMS::Responses::Document.new(document_id: "1", filename: "filename.pdf", doc_type: "123",
                                        source: "SRC", received_at: Time.zone.now,
                                        mime_type: "application/pdf"),
          VBMS::Responses::Document.new(document_id: "2", filename: "filename.pdf", doc_type: "123",
                                        source: "SRC", received_at: Time.zone.now,
                                        mime_type: "application/pdf")
        ]
      end

      it "saves download state for each document" do
        expect(Dir[Rails.root + "tmp/files/#{download.id}/*"].size).to eq(2)

        Document.all.each_with_index do |document, i|
          expect(document).to be_success
          expect(document.filepath).to eq((Rails.root + "tmp/files/#{download.id}/#{i}-filename.pdf").to_s)
          expect(File.exist?(document.filepath)).to be_truthy
        end
      end
    end
  end

  context "#package_contents" do
    let(:file) { "file content" }

    before do
      # clean files
      FileUtils.rm_rf(Rails.application.config.download_filepath)

      allow(VBMSService).to receive(:fetch_document_file) do |document|
        fail VBMS::ClientError if document.document_id != "1"
        file
      end

      download_documents.create_documents
      download_documents.download_contents
      download_documents.package_contents
    end

    it "packages files into zip and completes" do
      Zip::File.open(Rails.root + "tmp/files/#{download.id}/documents.zip") do |zip_file|
        expect(zip_file.glob("filename.pdf").first).to_not be_nil
      end

      expect(download).to be_complete
    end
  end
end
