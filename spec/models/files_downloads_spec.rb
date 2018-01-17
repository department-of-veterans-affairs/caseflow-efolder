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

    context "when recently downloaded the files" do
      it "does not start the job" do
        manifest.update(fetched_files_status: :finished, fetched_files_at: 2.hours.ago)
        subject
        expect(V2::PackageFilesJob).to_not have_received(:perform_later)
      end
    end

    context "when files are expired" do
      it "starts the job" do
        manifest.update(fetched_files_status: :finished, fetched_files_at: 4.days.ago)
        subject
        expect(manifest.fetched_files_status).to eq "pending"
        expect(V2::PackageFilesJob).to have_received(:perform_later)
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
end
