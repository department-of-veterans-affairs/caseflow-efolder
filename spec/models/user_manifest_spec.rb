describe Manifest do
  context "#save_files_and_package!" do
    before do
      allow(V2::PackageFilesJob).to receive(:perform_later)
    end

    let(:user) { User.create(css_id: "Foo", station_id: "112") }
    let(:manifest) { Manifest.find_or_create_by_user(user: user, file_number: "1234") }
    let(:user_manifest) { manifest.user_manifests.last }

    subject { user_manifest.save_files_and_package! }

    context "when never downloaded the files" do
      it "starts the jobs" do
        expect(user_manifest.status).to eq "initialized"
        subject
        expect(user_manifest.status).to eq "pending"
        expect(V2::PackageFilesJob).to have_received(:perform_later).once
      end
    end

    context "when recently downloaded the files" do
      it "does not start the job" do
        user_manifest.update(status: :finished, fetched_files_at: 2.hours.ago)
        expect(V2::PackageFilesJob).to_not have_received(:perform_later)
      end
    end

    context "when previously failed to download the files" do
      it "starts the job" do
        user_manifest.update(status: :failed, fetched_files_at: 2.hours.ago)
        subject
        expect(V2::PackageFilesJob).to have_received(:perform_later).once
      end
    end
  end
end
