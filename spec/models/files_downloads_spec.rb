describe FilesDownload do
  context "#start!" do
    before do
      allow(V2::PackageFilesJob).to receive(:perform_later)
    end

    let(:user) { User.create(css_id: "Foo", station_id: "112") }
    let(:manifest) { Manifest.find_or_create_by_user(user: user, file_number: "1234") }
    let(:files_download) { manifest.files_downloads.last }

    subject { files_download.start! }

    context "when never downloaded the files" do
      it "starts the jobs" do
        expect(manifest.fetched_files_status).to eq "initialized"
        subject
        expect(manifest.fetched_files_status).to eq "pending"
        expect(V2::PackageFilesJob).to have_received(:perform_later).once
        expect(files_download.requested_zip_at).to_not eq nil
      end
    end

    context "when the job is already pending" do
      it "starts the job" do
        manifest.update(fetched_files_status: :pending, fetched_files_at: 2.hours.ago)
        subject
        expect(V2::PackageFilesJob).to_not have_received(:perform_later)
      end
    end

    context "when previously failed to download the files" do
      it "starts the job" do
        manifest.update(fetched_files_status: :failed, fetched_files_at: 2.hours.ago)
        subject
        expect(V2::PackageFilesJob).to have_received(:perform_later).once
      end
    end
  end

  context ".find_with_manifest" do
    let!(:user) { User.create(css_id: "Foo", station_id: "112") }
    let!(:manifest) { Manifest.find_or_create_by_user(user: user, file_number: "1234") }

    it "includes sources and records" do
      files_download = described_class.find_with_manifest(user_id: user.id, manifest_id: manifest.id)

      expect(files_download).to eq(manifest.files_downloads.last)
    end
  end
end
