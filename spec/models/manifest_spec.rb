describe Manifest do
  context "#start!" do
    before do
      allow(V2::DownloadManifestJob).to receive(:perform_now)
    end

    let(:manifest) { Manifest.create(file_number: "1234") }

    subject { manifest.start! }

    context "when never fetched" do
      it "starts all jobs" do
        expect(manifest.sources.size).to eq 0
        subject
        expect(manifest.sources.size).to eq 2
        expect(V2::DownloadManifestJob).to have_received(:perform_now).twice
      end
    end

    context "when all manifests are current" do
      it "does not start any jobs" do
        manifest.sources.create(source: "VVA", status: :success, fetched_at: 2.hours.ago)
        manifest.sources.create(source: "VBMS", status: :success, fetched_at: 2.hours.ago)
        subject
        expect(V2::DownloadManifestJob).to_not have_received(:perform_now)
      end
    end

    context "when one manifest is expired" do
      it "starts one job" do
        manifest.sources.create(source: "VVA", status: :success, fetched_at: 2.hours.ago)
        manifest.sources.create(source: "VBMS", status: :success, fetched_at: 5.hours.ago)
        subject
        expect(V2::DownloadManifestJob).to have_received(:perform_now).once
      end
    end
  end

  context "#veteran_first_name" do
  end
end