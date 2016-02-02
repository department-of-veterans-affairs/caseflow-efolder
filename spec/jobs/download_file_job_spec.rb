describe DownloadFileJob do
  context "#perform" do
    let(:download) { Download.create! }

    context "when document list is empty" do
      before do
        allow(VBMSService).to receive(:fetch_documents_for).and_return([])
        DownloadFileJob.perform_now(download)
      end

      it "saves download status as :no_documents" do
        expect(download.reload).to be_no_documents
      end
    end

    context "when VBMS client fails" do
      before do
        allow(VBMSService).to receive(:fetch_documents_for).and_raise(VBMS::ClientError)
        DownloadFileJob.perform_now(download)
      end

      it "saves download status as :no_documents" do
        expect(download.reload).to be_no_documents
      end
    end

    context "when VBMS client returns non-empty document list" do
      before do
        allow(VBMSService).to receive(:fetch_documents_for).and_return(
          [
            VBMS::Responses::Document.new(document_id: "1"),
            VBMS::Responses::Document.new(document_id: "2")
          ])
      end

      context "before documents are downloaded" do
        before do
          # stub download documents to noop
          @download_documents = double("download_documents", perform: nil)
          allow(DownloadDocuments).to receive(:new).and_return(@download_documents)

          DownloadFileJob.perform_now(download)
        end

        it "saves download status as pending documents" do
          expect(download.reload).to be_pending_documents
        end
      end
    end
  end
end
