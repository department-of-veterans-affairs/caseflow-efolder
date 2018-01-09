# frozen_string_literal: true

describe Manifest do
  context "#start!" do
    before do
      allow(V2::DownloadManifestJob).to receive(:perform_later)
    end

    let(:manifest) { Manifest.create(file_number: "1234") }

    subject { manifest.start! }

    context "when never fetched" do
      it "starts all jobs" do
        expect(manifest.sources.size).to eq 0
        subject
        expect(manifest.sources.size).to eq 2
        expect(V2::DownloadManifestJob).to have_received(:perform_later).twice
      end
    end

    context "when all manifests are current" do
      it "does not start any jobs" do
        manifest.sources.create(source: "VVA", status: :success, fetched_at: 2.hours.ago)
        manifest.sources.create(source: "VBMS", status: :success, fetched_at: 2.hours.ago)
        subject
        expect(V2::DownloadManifestJob).to_not have_received(:perform_later)
      end
    end

    context "when one manifest is expired" do
      it "starts one job" do
        manifest.sources.create(source: "VVA", status: :success, fetched_at: 2.hours.ago)
        manifest.sources.create(source: "VBMS", status: :success, fetched_at: 5.hours.ago)
        subject
        expect(V2::DownloadManifestJob).to have_received(:perform_later).once
      end
    end
  end

  context ".find_or_create_by_user" do
    let(:user) { User.create(css_id: "Foo", station_id: "112") }
    subject { Manifest.find_or_create_by_user(user: user, file_number: "1234") }

    it "creates manifest and user manifest records" do
      subject
      manifest = Manifest.first
      user_manifest = UserManifest.first
      expect(manifest.file_number).to eq "1234"
      expect(user_manifest.user).to eq user
      expect(user_manifest.manifest).to eq manifest

      Manifest.find_or_create_by_user(user: user, file_number: "1234")
      expect(Manifest.count).to eq 1
      expect(UserManifest.count).to eq 2
      user_manifest = UserManifest.second
      expect(user_manifest.user).to eq user
      expect(user_manifest.manifest).to eq manifest
    end
  end

  context "#veteran_first_name" do
    let(:manifest) { Manifest.create(file_number: "445566", veteran_first_name: veteran_first_name) }

    let(:veteran_record) do
      {
        "veteran_first_name" => name_from_bgs,
        "veteran_last_name" => "Juniper",
        "veteran_last_four_ssn" => "6789"
      }
    end

    before do
      allow_any_instance_of(Fakes::BGSService).to receive(:veteran_info).and_return("445566" => veteran_record)
    end

    subject { manifest.veteran_first_name }

    context "when veteran first name is an empty string" do
      let(:veteran_first_name) { "" }
      let(:name_from_bgs) { "June" }

      it "should not re-set the veteran first name" do
        expect(manifest.reload.veteran_first_name).to eq ""
      end
    end

    context "when veteran first name is nil" do
      let(:veteran_first_name) { nil }

      context "and the BGS name is not nil" do
        let(:name_from_bgs) { "June" }

        it "should set the veteran first name to the BGS name" do
          expect(manifest.reload.veteran_first_name).to eq "June"
        end
      end

      context "and the name from BGS is nil" do
        let(:name_from_bgs) { nil }

        it "should set the veteran first name to an empty string" do
          expect(manifest.reload.veteran_first_name).to eq ""
        end
      end
    end
  end
end
