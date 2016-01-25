require 'fileutils'

describe DownloadDocuments do
	let(:download) { Download.create! }

	let(:vbms_documents) {[
		VBMS::Responses::Document.new(document_id: "1", filename: "filename.pdf", doc_type: "123",
			source: "SRC", received_at: Time.now, mime_type: 'application/pdf'),
		VBMS::Responses::Document.new(document_id: "2")
	]}

	let(:download_documents) {
		DownloadDocuments.new(download: download, vbms_documents: vbms_documents)
	}

	context "#save_document_file" do
		let(:document) {
			Document.new(document_id: "21012", filename: "happyfile.pdf")
		}

		before do
			# clean files
			FileUtils.rm_rf(Rails.application.config.download_filepath)
		end

		it "creates a file in the correct directory and returns filename" do
			filename = download_documents.save_document_file(document, "hi")	
			expect(File.exist?("tmp/files/21012/happyfile.pdf")).to be_truthy
			expect(filename).to eq("tmp/files/21012/happyfile.pdf")
		end
	end

	context "#perform" do
		context "without downloading document content" do
			before do
				allow(download_documents).to receive(:download_document_contents)
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
			let(:file) { double("file") }

			before do
				allow(download_documents).to receive(:save_document_file).and_return("my/local/filename.pdf")
	
				allow(VBMSService).to receive(:fetch_document_file) do |document|
					if document.document_id == "1"
						file
					else
						raise VBMS::ClientError
					end
				end

				download_documents.perform
			end

			it "saves download state for each document" do
				successful_document = Document.first
				expect(successful_document).to be_success
				expect(successful_document.filename).to eq("my/local/filename.pdf")

				errored_document = Document.last
				expect(errored_document).to be_failed
			end
		end
	end
end