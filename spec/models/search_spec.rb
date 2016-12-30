require "rails_helper"

describe Search do
  let(:user) { User.create(css_id: "NICKSABAN", station_id: "200") }
  let(:file_number) { "12341234" }
  let(:status) { nil }
  let(:search) do
    Search.new(user: user, file_number: file_number, status: status)
  end

  context "#sanitized_file_number" do
    subject { search.sanitized_file_number }

    context "when file_number has trailing spaces" do
      let(:file_number) { "12341234   " }
      it { is_expected.to eq("12341234") }
    end

    context "when file_number is nil" do
      let(:file_number) { nil }
      it { is_expected.to eq("") }
    end
  end

  context "#perform!" do
    let(:file_number) { "22223333  " }
    subject { search.perform! }

    before do
      Fakes::BGSService.veteran_info =
        { "22223333" =>
          {
            "veteran_first_name" => "John",
            "veteran_last_name" => "McJohn"
          }
        }
      Fakes::BGSService.sensitive_files = {}
      Download.bgs_service = Fakes::BGSService
      allow(GetDownloadManifestJob).to receive(:perform_later)

      Download.delete_all
    end

    it "creates a download" do
      expect(subject).to be_truthy
      expect(search.download.file_number).to eq("22223333")
      expect(search.download.user.css_id).to eq("NICKSABAN")
      expect(search.download.user.station_id).to eq("200")
    end

    it "creates a job to fetch the download manifest" do
      expect(subject).to be_truthy
      expect(GetDownloadManifestJob).to have_received(:perform_later)
    end

    it "saves its status as download_created" do
      expect(subject).to be_truthy
      expect(search.reload).to be_download_created
      expect(search.user.css_id).to eq("NICKSABAN")
      expect(search.user.station_id).to eq("200")
    end

    context "a download already exists for that user and file_number" do
      before do
        @existing_download = Download.create(file_number: "22223333", user: user)
      end

      it "uses that download" do
        expect(subject).to be_truthy
        expect(search.download.id).to eq(@existing_download.id)
        expect(search.reload).to be_download_found
      end

      context "when that download is inactive" do
        before do
          @existing_download.update_attributes!(created_at: 4.days.ago)
        end

        it "creates a new download" do
          expect(subject).to be_truthy
          expect(search.reload).to be_download_created
          expect(search.download.id).to_not eq(@existing_download.id)
        end
      end
    end

    context "when case is not found in BGS" do
      let(:file_number) { "33334444" }

      it "sets search to veteran_not_found and returns false" do
        expect(subject).to be_falsy
        expect(search.reload).to be_veteran_not_found
      end
    end

    context "when the download has vbms connection error" do
      before do
        @existing_download = Download.create(
          file_number: "22223333",
          status: :vbms_connection_error
        )
      end

      it "creates a new download" do
        expect(@existing_download).to be_truthy
        expect(subject).to be_truthy
        expect(search.reload).to be_download_created
        expect(search.download.id).to_not eq(@existing_download.id)
      end
    end

    context "when user cannot access file with that file_number" do
      before do
        Fakes::BGSService.sensitive_files = { "22223333" => true }
      end

      it "sets search to access_denied and returns false" do
        expect(subject).to be_falsy
        expect(search.reload).to be_access_denied
      end
    end
  end
end
