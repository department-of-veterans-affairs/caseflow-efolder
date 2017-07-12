require "rails_helper"

describe "Download" do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))

    Download.bgs_service = Fakes::BGSService
    Fakes::BGSService.veteran_info = {
      "1234" => {
        "veteran_first_name" => "Stan",
        "veteran_last_name" => "Lee",
        "veteran_last_four_ssn" => "0987"
      }
    }
  end
  after { Timecop.return }

  let(:file_number) { "1234" }
  let(:download) { Download.create(file_number: file_number) }

  context ".new" do
    subject { Download.new(file_number: file_number) }

    context "when file number is set" do
      before do
        Download.bgs_service = Fakes::BGSService
        Fakes::BGSService.veteran_info = {
          "1234" => {
            "veteran_first_name" => "Stan",
            "veteran_last_name" => "Lee",
            "veteran_last_four_ssn" => "0987"
          }
        }
      end

      it "indicates that veteran info is missing if it is" do
        # veteran names & ssn are fetched right before persistance
        # to the db, so before save is called, that info won't be
        # present
        expect(subject.missing_veteran_info?).to eq(true)
      end

      it "sets veteran name" do
        subject.save!
        expect(subject.veteran_name).to eq("Stan Lee")
      end
    end

    context "when no file number" do
      let(:file_number) { nil }

      it "doesn't set veteran name" do
        expect(subject.veteran_name).to be_nil
      end
    end
  end

  context ".start_fetch_manifest" do
    it "creates a job to fetch the download manifest" do
      expect(DownloadManifestJob).to receive(:perform_later)
      download.start_fetch_manifest
    end
  end

  context "veteran_name" do
    subject { download.veteran_name }
    it { is_expected.to eq("Stan Lee") }
  end

  context "#time_to_fetch_manifest" do
    let(:download) do
      Download.create(
        file_number: file_number,
        created_at: 4.hours.ago,
        manifest_fetched_at: 1.hour.ago
      )
    end

    subject { download.time_to_fetch_manifest }

    it { is_expected.to eq(3.hours) }
  end

  context "#time_to_fetch_files" do
    let(:download) do
      Download.create(
        file_number: file_number,
        started_at: 10.hours.ago,
        completed_at: 3.hours.ago
      )
    end

    subject { download.time_to_fetch_files }

    it { is_expected.to eq(7.hours) }
  end

  context "#s3_filename" do
    subject { download.s3_filename }
    it { is_expected.to eq("#{download.id}-download.zip") }
  end

  context "package_filename" do
    subject { download.package_filename }
    it { is_expected.to eq("Lee, Stan - 0987.zip") }
  end

  context "#stalled?" do
    subject { download.stalled? }

    context "when not pending_documents" do
      before { download.status = :packaging_contents }
      it { is_expected.to be_falsey }
    end

    context "when pending_documents" do
      before { download.status = :pending_documents }

      context "when last updated after the threshold" do
        before do
          download.update_attributes(updated_at: 11.minutes.ago)
        end

        it { is_expected.to be_truthy }
      end

      context "when most recent pending document started before the threshold" do
        before do
          download.update_attributes(updated_at: 9.minutes.ago)
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  context "#reset!" do
    before do
      download.update_attributes(status: :complete_with_errors)

      @documents = [
        download.documents.create(vbms_filename: "roll.pdf", mime_type: "application/pdf", download_status: :failed),
        download.documents.create(vbms_filename: "tide.pdf", mime_type: "application/pdf", download_status: :success)
      ]
    end

    it "resets status of download and documents" do
      download.reset!

      expect(download.reload).to be_pending_documents
      expect(@documents.first.reload).to be_pending
      expect(@documents.first.filepath).to be_nil
      expect(@documents.first.completed_at).to eq nil
      expect(@documents.first.pending?).to eq true
      expect(@documents.last.reload).to be_pending
      expect(@documents.last.filepath).to be_nil
      expect(@documents.last.completed_at).to eq nil
      expect(@documents.last.pending?).to eq true
    end
  end

  context "#download_dir" do
    subject { download.download_dir }

    it "returns a download directory" do
      expect(subject).to eq File.join(Rails.application.config.download_filepath, download.id.to_s)
    end
  end

  context "#estimated_to_complete_at" do
    before { download.documents.create!(started_at: Time.zone.now) }
    subject { download.estimated_to_complete_at }
    let(:document) { download.documents.first }
    let(:document_class) { Document }

    context "when download is fetching manifest" do
      before { download.update_attributes!(status: :fetching_manifest) }
      it { is_expected.to be_nil }
    end

    context "when download is pending documents" do
      before do
        download.update_attributes!(status: :pending_documents)
        document_class.stub(:historical_average_download_rate) { 5.minutes }
      end

      context "when documents have been downloaded" do
        it "calculates correctly with one download remaining" do
          expect(subject).to eq(5.minutes.from_now)
        end

        it "calculates correctly with two downloads completed" do
          download.documents.create!(started_at: 7.minutes.ago, completed_at: 3.minutes.ago)
          # Still 5 minutes
          expect(subject).to eq(5.minutes.from_now)
        end

        it "calculates corrrectly with two downloads left" do
          download.documents.create!
          expect(subject).to eq(10.minutes.from_now)
        end
      end

      context "when no historical data exists" do
        before { document_class.stub(:historical_average_download_rate) { nil } }
        it { is_expected.to be_nil }
      end
    end
  end

  context ".top_users" do
    before do
      user1 = User.new(css_id: "RADIOHEAD", station_id: "203")
      user2 = User.new(css_id: "ARCADE_FIRE", station_id: "102", email: "archade_fire@example.com")
      user3 = User.new(css_id: "QUEEN", station_id: "103", email: "queen@example.com")
      2.times { Download.create(user: user1) }
      10.times { Download.create(user: user2) }
      12.times { Download.create(user: user3) }
      # should ignore downloads that have nil user values
      4.times { Download.create }
    end

    subject { Download.top_users(downloads: Download.all) }

    it "finds the top 3 users by number of downloads" do
      expect(subject[0][:id]).to eq("queen@example.com (QUEEN - Station 103)")
      expect(subject[0][:count]).to eq(12)
      expect(subject[1][:id]).to eq("archade_fire@example.com (ARCADE_FIRE - Station 102)")
      expect(subject[1][:count]).to eq(10)
      expect(subject[2][:id]).to eq("No Email Recorded (RADIOHEAD - Station 203)")
      expect(subject[2][:count]).to eq(2)
    end
  end

  context ".find_or_create_by_user_and_file" do
    subject { Download.find_or_create_by_user_and_file(user.id, file_number) }
    let(:user) { User.create(css_id: "WALTER", station_id: "123") }
    let(:file_number) { "123" }

    context "retrieves most recent existing record" do
      let!(:old_download) { Download.create(user: user, file_number: file_number, created_at: 2.seconds.ago) }
      let!(:new_download) { Download.create(user: user, file_number: file_number, created_at: 1.second.ago) }

      it { is_expected.to eq(new_download) }
    end

    context "creates a new download when no one exists" do
      it do
        expect(subject.user_id).to eq(user.id)
        expect(subject.file_number).to eq(file_number)
      end
    end
  end

  context "#css_id_string" do
    subject { download.css_id_string }
    let(:download) { Download.new(user: user) }

    context "when user is set" do
      let(:user) { User.new(css_id: "WALTER", station_id: "123") }
      it { is_expected.to eq("(WALTER - Station 123)") }
    end

    context "when user is nil" do
      let(:user) { nil }
      it { is_expected.to eq("Unknown") }
    end
  end

  context "#progress_percentage" do
    subject { download.progress_percentage }

    context "when download is fetching_manifest" do
      before { download.status = :fetching_manifest }
      it { is_expected.to eq(20) }
    end

    context "when pending_documents" do
      before do
        download.status = :pending_documents
        @document1 = download.documents.create(document_id: "1")
        @document2 = download.documents.create(document_id: "2")
        @document3 = download.documents.create(document_id: "3")
      end

      context "when all documents are pending" do
        it { is_expected.to eq(40) }
      end

      context "when some documents are complete" do
        before { @document1.download_status = :success }
        it { is_expected.to eq(60) }
      end
    end

    context "when complete" do
      before { download.status = :complete_success }
      it { is_expected.to eq(100) }
    end

    context "when no_documents" do
      before { download.status = :no_documents }
      it { is_expected.to eq(100) }
    end
  end

  context "#force_fetch_manifest_if_expired!" do
    context "when the manifest has never been fetched" do
      it "starts the manifest job" do
        allow(DownloadManifestJob).to receive(:perform_now)
        download.force_fetch_manifest_if_expired!
        expect(DownloadManifestJob).to have_received(:perform_now)
      end
    end

    context "when the manifest was fetched more than 3 hours ago" do
      before do
        download.update_attributes!(manifest_fetched_at: Time.zone.now - 4.hours)
      end

      it "starts the manifest job" do
        allow(DownloadManifestJob).to receive(:perform_now)
        download.force_fetch_manifest_if_expired!
        expect(DownloadManifestJob).to have_received(:perform_now)
      end
    end

    context "when the manifest was fetched less than 3 hours ago" do
      before do
        download.update_attributes!(manifest_fetched_at: Time.zone.now - 2.hours)
      end

      it "does not start the manifest job" do
        allow(DownloadManifestJob).to receive(:perform_now)
        download.force_fetch_manifest_if_expired!
        expect(DownloadManifestJob).to_not have_received(:perform_now)
      end
    end
  end

  context "#prepare_files_for_api!" do
    before do
      allow(VBMSService).to receive(:fetch_documents_for).and_return(vbms_documents)
    end

    context "when VBMS returns documents" do
      let(:vbms_documents) do
        [
          OpenStruct.new(
            document_id: "1",
            received_at: "1/2/2017",
            type_id: "123"
          )
        ]
      end

      it "saves documents to DB" do
        download.prepare_files_for_api!

        expect(download.documents.size).to eq(1)
        expect(download.documents[0].document_id).to eq(vbms_documents[0].document_id)
        expect(download.documents[0].received_at).to eq(vbms_documents[0].received_at.to_datetime)
        expect(download.documents[0].type_id).to eq(vbms_documents[0].type_id)
      end

      context "when start_download is true" do
        it "starts the download job" do
          expect(SaveFilesInS3Job).to receive(:perform_later)
          download.prepare_files_for_api!(start_download: true)
        end
      end
    end

    context "when VBMS returns no documents" do
      let(:vbms_documents) { [] }

      it "raises an error" do
        expect { download.prepare_files_for_api!(start_download: true) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
