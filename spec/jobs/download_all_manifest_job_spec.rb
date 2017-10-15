describe DownloadAllManifestJob do
  context "#perform" do
    let(:download) { Download.create }

    context "when document list is empty" do
      before do
        allow(VBMSService).to receive(:fetch_documents_for).and_return([])
        DownloadAllManifestJob.perform_now(download)
      end

      it "saves download status as :no_documents" do
        expect(download.reload).to be_no_documents
      end
    end

    context "when VBMS client fails" do
      before do
        allow(VBMSService).to receive(:fetch_documents_for).and_raise(VBMS::ClientError)
      end
      it "saves download status as :vbms_connection_error" do
        expect(DownloadAllManifestJob.perform_now(download)).to be_nil
        expect(download.reload).to be_vbms_connection_error
      end
    end

    context "when VBMS client returns non-empty document list" do
      before do
        allow(VBMSService).to receive(:fetch_documents_for).and_return(
          [
            OpenStruct.new(document_id: "1"),
            OpenStruct.new(document_id: "2")
          ])

        DownloadAllManifestJob.perform_now(download)
      end

      it "saves download status as pending confirmation and creates documents" do
        expect(download.reload).to be_pending_confirmation
        expect(download.documents.count).to eq(2)
      end
    end

    context "when VVA client fails" do
      before do
        allow(VVAService).to receive(:fetch_documents_for).and_raise(VVA::ClientError)
      end
      it "saves download status as :vbms_connection_error" do
        expect(DownloadAllManifestJob.perform_now(download)).to be_nil
        expect(download.reload).to be_vva_connection_error
      end
    end

    context "when VBMS returns non-empty document list and VVA returns an error" do
      before do
        allow(VBMSService).to receive(:fetch_documents_for).and_return(
          [
            OpenStruct.new(document_id: "1"),
            OpenStruct.new(document_id: "2")
          ])
        allow(VVAService).to receive(:fetch_documents_for).and_raise(VVA::ClientError)

        DownloadAllManifestJob.perform_now(download)
      end

      it "saves download status as vva_connection_error and does not create documents" do
        expect(DownloadAllManifestJob.perform_now(download)).to be_nil
        expect(download.reload).to be_vva_connection_error
      end
    end

  end
end
