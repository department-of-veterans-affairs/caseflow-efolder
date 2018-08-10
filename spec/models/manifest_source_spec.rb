describe ManifestSource do
  context "#source" do
    let(:manifest) { Manifest.create(file_number: "1234") }
    let(:source) { ManifestSource.create(name: name, manifest: manifest) }

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

  context "#expiry_hours" do
    let(:manifest) { Manifest.create(file_number: "1234") }
    let(:source) { ManifestSource.create(name: %w[VBMS VVA].sample, manifest: manifest) }

    subject { source.expiry_hours }

    context "when current user has a Reader role" do
      let!(:current_user) { User.authenticate!(roles: ["Reader"]) }
      it { is_expected.to eq Manifest::API_HOURS_UNTIL_EXPIRY }
    end

    context "when current user has a Download eFolder role" do
      let!(:current_user) { User.authenticate!(roles: ["Download eFolder"]) }
      it { is_expected.to eq Manifest::UI_HOURS_UNTIL_EXPIRY }
    end

    context "when current user has no roles" do
      let!(:current_user) { User.authenticate!(roles: []) }
      it { is_expected.to eq Manifest::API_HOURS_UNTIL_EXPIRY }
    end
  end

  context "#start!" do
    before do
      allow(V2::DownloadManifestJob).to receive(:perform_later)
    end

    let(:manifest) { Manifest.create(file_number: "1234") }
    let(:source) { ManifestSource.create(name: %w[VBMS VVA].sample, manifest: manifest) }

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

    context "when starting the job fails" do
      before do
        allow(V2::DownloadManifestJob).to receive(:perform_later).and_raise(StandardError.new)
      end

      it "status ends in state initialized" do
        expect { subject }.to raise_error(StandardError)
        expect(source.status).to eq("initialized")
      end
    end
  end
end
