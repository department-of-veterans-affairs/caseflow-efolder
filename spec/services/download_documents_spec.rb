require "fileutils"
require "zip"

describe DownloadDocuments do
  before { Download.delete_all; Document.delete_all }

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
      download.documents.build(document_id: "3", filename: "happyfile.pdf")
    end

    before do
      # clean files
      FileUtils.rm_rf(Rails.application.config.download_filepath)
    end

    it "creates a file in the correct directory and returns filename" do
      filename = download_documents.save_document_file(document, "hi")
      expect(File.exist?("tmp/files/#{download.id}/happyfile.pdf")).to be_truthy
      expect(filename).to eq("tmp/files/#{download.id}/happyfile.pdf")
    end
  end

  context "#perform" do
    context "without downloading document content" do
      before do
        allow(download_documents).to receive(:download_document_contents)
        allow(download_documents).to receive(:package_documents)
        download_documents.perform
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

    context "with downloading document content" do
      let(:file) { "file content" }

      before do
        # clean files
        FileUtils.rm_rf(Rails.application.config.download_filepath)

        allow(VBMSService).to receive(:fetch_document_file) do |document|
          fail VBMS::ClientError if document.document_id != "1"
          file
        end

        download_documents.perform
      end

      it "saves download state for each document" do
        successful_document = Document.first
        expect(successful_document).to be_success
        expect(successful_document.filepath).to eq("tmp/files/#{download.id}/filename.pdf")

        errored_document = Document.last
        expect(errored_document).to be_failed

        expect(download).to be_complete
      end

      it "packages files into zip" do
        Zip::File.open("tmp/files/#{download.id}/documents.zip") do |zip_file|
          expect(zip_file.glob("filename.pdf").first).to_not be_nil
        end
      end
    end
  end
end
