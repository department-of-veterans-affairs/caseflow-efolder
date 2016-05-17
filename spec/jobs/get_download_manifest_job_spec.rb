describe GetDownloadManifestJob do
  context "#perform" do
    let(:download) { Download.create! }

    context "when document list is empty" do
      before do
        allow(VBMSService).to receive(:fetch_documents_for).and_return([])
        GetDownloadManifestJob.perform_now(download)
      end

      it "saves download status as :no_documents" do
        expect(download.reload).to be_no_documents
      end
    end

    context "when VBMS client fails" do
      before do
        allow(VBMSService).to receive(:fetch_documents_for).and_raise(VBMS::ClientError)
        GetDownloadManifestJob.perform_now(download)
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

        GetDownloadManifestJob.perform_now(download)
      end

      it "saves download status as pending confirmation and creates documents" do
        expect(download.reload).to be_pending_confirmation
        expect(download.documents.count).to eq(2)
      end
    end
  end
end
