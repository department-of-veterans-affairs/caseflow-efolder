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

  context ".find_or_create_by_user" do
    let(:user) { User.create(css_id: "Foo", station_id: "112") }
    subject { Manifest.find_or_create_by_user(user: user, file_number: "1234") }

    it "should create objects" do
      subject
      expect(Manifest.count).to eq 1
      expect(UserManifest.count).to eq 1
      expect(Manifest.first.file_number).to eq "1234"
      expect(UserManifest.first.user).to eq user
      expect(UserManifest.first.manifest).to eq Manifest.first
    end
  end

  context "#veteran_first_name" do
    let(:manifest) { Manifest.create(file_number: "445566", veteran_first_name: name) }

    let(:veteran_record) do
      {
        "veteran_first_name" => "June",
        "veteran_last_name" => "Juniper",
        "veteran_last_four_ssn" => "6789"
      }
    end

    before do
      Fakes::BGSService.veteran_info = { "445566" => veteran_record }
    end

    subject { manifest.veteran_first_name }

    context "when veteran first name is empty string" do
      let(:name) { "" }

      it "should not set the veteran_first_name" do
        expect(manifest.reload.veteran_first_name).to eq ""
      end
    end

    context "when veteran first name is nil" do
      let(:name) { nil }

      it "should set the veteran_first_name" do
        expect(manifest.reload.veteran_first_name).to eq "June"
      end
    end
  end
end
