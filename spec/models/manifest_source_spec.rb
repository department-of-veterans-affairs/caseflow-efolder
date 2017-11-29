describe ManifestSource do
  context "#start!" do
    before do
      allow(V2::DownloadManifestJob).to receive(:perform_now)
    end

    let(:manifest) { Manifest.create(file_number: "1234") }
    let(:source) { ManifestSource.create(source: ["VBMS", "VVA"].sample, manifest: manifest) }

    subject { source.start! }

    context "when never fetched" do
      it "starts the manifest job" do
        subject
        expect(V2::DownloadManifestJob).to have_received(:perform_now)
      end
    end

    context "when fetched more than 3 hours ago" do
      before do
        source.update_attributes!(fetched_at: Time.zone.now - 4.hours, status: :success)
      end

      it "starts the manifest job" do
        subject
        expect(V2::DownloadManifestJob).to have_received(:perform_now)
      end
    end

    context "when failed" do
      before do
        source.update_attributes!(fetched_at: Time.zone.now - 2.hours, status: :failed)
      end

      it "starts the manifest job" do
        subject
        expect(V2::DownloadManifestJob).to have_received(:perform_now)
      end
    end

    context "when fetched less than 3 hours ago" do
      before do
        source.update_attributes!(fetched_at: Time.zone.now - 2.hours, status: :success)
      end

      it "starts the manifest job" do
        subject
        expect(V2::DownloadManifestJob).to_not have_received(:perform_now)
      end
    end
  end
end