# frozen_string_literal: true

describe ManifestSource do
  context "#source" do
    let(:manifest) { Manifest.create(file_number: "1234") }
    let(:source) { ManifestSource.create(source: name, manifest: manifest) }

    subject { source.service }

    context "when VVA" do
      let(:name) { "VVA" }
      it { is_expected.to eq VVAService }
    end

    context "when VBMS" do
      let(:name) { VBMS }
      it { is_expected.to eq VBMSService }
    end

    context "when unknown" do
      let(:name) { "NON" }
      it { is_expected.to eq nil }
    end
  end

  context "#start!" do
    before do
      allow(V2::DownloadManifestJob).to receive(:perform_later)
    end

    let(:manifest) { Manifest.create(file_number: "1234") }
    let(:source) { ManifestSource.create(source: %w[VBMS VVA].sample, manifest: manifest) }

    subject { source.start! }

    context "when never fetched" do
      it "starts the manifest job" do
        subject
        expect(V2::DownloadManifestJob).to have_received(:perform_later)
      end
    end

    context "when fetched more than 3 hours ago" do
      before do
        source.update_attributes!(fetched_at: Time.zone.now - 4.hours, status: :success)
      end

      it "starts the manifest job" do
        subject
        expect(V2::DownloadManifestJob).to have_received(:perform_later)
      end
    end

    context "when failed" do
      before do
        source.update_attributes!(fetched_at: Time.zone.now - 2.hours, status: :failed)
      end

      it "starts the manifest job" do
        subject
        expect(V2::DownloadManifestJob).to have_received(:perform_later)
      end
    end

    context "when manifest is pending" do
      before do
        source.update_attributes!(fetched_at: Time.zone.now - 7.hours, status: :pending)
      end

      it "does not start the manifest job" do
        subject
        expect(V2::DownloadManifestJob).to_not have_received(:perform_later)
      end
    end

    context "when fetched less than 3 hours ago" do
      before do
        source.update_attributes!(fetched_at: Time.zone.now - 2.hours, status: :success)
      end

      it "does not start the manifest job" do
        subject
        expect(V2::DownloadManifestJob).to_not have_received(:perform_later)
      end
    end
  end
end
