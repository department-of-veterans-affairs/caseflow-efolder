describe V2::DownloadManifestJob do
  context "#perform" do
    let(:manifest) { Manifest.create(file_number: "1234") }
    let(:source) { ManifestSource.create(source: %w[VBMS VVA].sample, manifest: manifest) }

    let(:documents) do
      [
        OpenStruct.new(document_id: "1", series_id: "1234"),
        OpenStruct.new(document_id: "2", series_id: "5678")
      ]
    end

    subject { V2::DownloadManifestJob.perform_now(source) }

    before do
      allow(V2::SaveFilesInS3Job).to receive(:perform_later)
    end

    context "when document list is empty" do
      before do
        allow(Fakes::DocumentService).to receive(:v2_fetch_documents_for).and_return([])
      end

      it "does not create any records and does not start caching files in s3" do
        subject
        expect(manifest.records).to eq []
        expect(V2::SaveFilesInS3Job).to_not have_received(:perform_later)
      end
    end

    context "when any error" do
      before do
        allow_any_instance_of(ManifestFetcher).to receive(:process).and_raise("Something went wrong")
      end

      it "it sets the status to failed" do
        expect { subject }.to raise_error("Something went wrong")
        expect(source.reload.status).to eq "failed"
      end
    end

    context "when document list is not empty" do
      before do
        allow(Fakes::DocumentService).to receive(:v2_fetch_documents_for).and_return(documents)
      end

      it "creates document records and starts caching files in s3" do
        subject
        expect(manifest.records.size).to eq 2
        # TODO: uncomment this line
        # expect(V2::SaveFilesInS3Job).to have_received(:perform_later)
      end
    end
  end
end
