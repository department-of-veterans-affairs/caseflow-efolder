describe DownloadManifestJob do
  context "#perform" do
    let(:download) { Download.create }

    context "when document list is empty" do
      before do
        allow(VBMSService).to receive(:fetch_documents_for).and_return([])
        DownloadManifestJob.perform_now(download)
      end

      it "saves download status as :no_documents" do
        expect(download.reload).to be_no_documents
      end
    end

    context "when VBMS client fails" do
      before do
        allow(VBMSService).to receive(:fetch_documents_for).and_raise(VBMS::ClientError)
      end
      context "saves download status as :vbms_connection_error" do
        after do
          expect(download.reload).to be_vbms_connection_error
        end

        context "when graceful is set to false" do
          it "does not return documents" do
            expect(DownloadManifestJob.perform_now(download)).to be_nil
          end
        end
        context "when graceful is set to true" do
          it "does return documents" do
            expect(DownloadManifestJob.perform_now(download, true)).to_not be_nil
          end
        end
      end
    end

    context "when VBMS client returns non-empty document list" do
      before do
        allow(VBMSService).to receive(:fetch_documents_for).and_return(
          [
            OpenStruct.new(document_id: "1"),
            OpenStruct.new(document_id: "2")
          ])

        DownloadManifestJob.perform_now(download)
      end

      it "saves download status as pending confirmation and creates documents" do
        expect(download.reload).to be_pending_confirmation
        expect(download.documents.count).to eq(2)
      end
    end
  end
end
