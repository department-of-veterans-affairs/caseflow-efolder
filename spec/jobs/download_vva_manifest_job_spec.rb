# frozen_string_literal: true

describe DownloadVVAManifestJob do
  context "#perform" do
    before do
      FeatureToggle.enable!(:vva_service)
    end
    let(:download) { Download.create }
    let(:vva_returned_docs) do
      [
        OpenStruct.new(document_id: "1"),
        OpenStruct.new(document_id: "2")
      ]
    end

    before do
      allow(VVAService).to receive(:fetch_documents_for).and_return(vva_returned_docs)
    end

    context "when vva is enabled" do
      it "creates documents and updates vva_manifest_fetched_at" do
        DownloadVVAManifestJob.perform_now(download)

        expect(download.reload.manifest_vva_fetched_at).to_not be_nil
        expect(download.documents.count).to eq(vva_returned_docs.length)
      end
    end

    context "when vva is disabled" do
      before do
        FeatureToggle.disable!(:vva_service)
      end

      it "doesn't create documents and or update vva_manifest_fetched_at" do
        DownloadVVAManifestJob.perform_now(download)

        expect(download.reload.manifest_vva_fetched_at).to be_nil
        expect(download.documents.count).to eq(0)
      end
    end
  end
end
