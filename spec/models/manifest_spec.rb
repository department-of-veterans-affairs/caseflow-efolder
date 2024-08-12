describe Manifest do
  describe "#start!" do
    let(:user) { User.create(css_id: "Foo", station_id: "112") }
    let(:manifest) { Manifest.create(file_number: "1234", user: user) }

    subject { manifest.start! }

    context "without sensitivity level check" do
      before do
        Timecop.freeze(Time.utc(2015, 12, 2, 17, 0, 0))
        allow(V2::DownloadManifestJob).to receive(:perform_later)
        expect(FeatureToggle).to receive(:enabled?).with(:check_user_sensitivity).and_return(false)
        expect(FeatureToggle).to receive(:enabled?).with(:skip_vva).and_return(false)
      end

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
          manifest.sources.create(name: "VVA", status: :success, fetched_at: 2.hours.ago)
          manifest.sources.create(name: "VBMS", status: :success, fetched_at: 2.hours.ago)
          subject
          expect(V2::DownloadManifestJob).to_not have_received(:perform_later)
        end
      end

      context "when one manifest is expired" do
        it "starts one job" do
          manifest.sources.create(name: "VVA", status: :success, fetched_at: 2.hours.ago)
          manifest.sources.create(name: "VBMS", status: :success, fetched_at: 5.hours.ago)
          subject
          expect(V2::DownloadManifestJob).to have_received(:perform_later).once
        end
      end
    end

    context "with sensitivity level check" do
      let(:mock_sensitivity_checker) { instance_double(SensitivityChecker) }

      before do
        allow(SensitivityChecker).to receive(:new).and_return(mock_sensitivity_checker)
      end

      context "when check_user_sensitivity feature toggle is enabled" do
        before { FeatureToggle.enable!(:check_user_sensitivity) }
        after { FeatureToggle.disable!(:check_user_sensitivity) }

        it "enqueues a job if the sensitivity check passes" do
          expect(mock_sensitivity_checker).to receive(:sensitivity_levels_compatible?)
            .with(user: user, veteran_file_number: "1234").and_return(true)
          expect(V2::DownloadManifestJob).to receive(:perform_later).twice

          subject
        end

        it "raises an exception if the sensitivity check fails" do
          expect(mock_sensitivity_checker).to receive(:sensitivity_levels_compatible?)
            .with(user: user, veteran_file_number: "1234").and_return(false)
          expect(V2::DownloadManifestJob).to_not receive(:perform_later)

          expect { subject }.to raise_error(BGS::SensitivityLevelCheckFailure)
        end
      end

      context "when check_user_sensitivity feature toggle is disabled" do
        before { FeatureToggle.disable!(:check_user_sensitivity) }

        it "enqueues a job to fetch the manifest" do
          expect(mock_sensitivity_checker).to_not receive(:sensitivity_levels_compatible?)
          expect(V2::DownloadManifestJob).to receive(:perform_later).twice

          subject
        end
      end
    end
  end

  context "#time_to_complete" do
    let(:manifest) { Manifest.create(file_number: "1234") }

    subject { manifest.time_to_complete }

    let!(:records) do
      [
        manifest.vbms_source.records.create(
          received_at: Time.utc(2015, 1, 3, 17, 0, 0),
          type_id: "123",
          status: :success,
          version_id: "{ABC123-DEF123-GHI456A}",
          series_id: "{ABC321-DEF123-GHI456A}",
          mime_type: "application/pdf"
        ),
        manifest.vva_source.records.create(
          received_at: Time.utc(2017, 1, 3, 17, 0, 0),
          type_id: "345",
          version_id: "{FDC123-DEF123-GHI456A}",
          series_id: "{KYC321-DEF123-GHI456A}",
          mime_type: "application/pdf"
        ),
        manifest.vbms_source.records.create(
          received_at: Time.utc(2016, 1, 3, 17, 0, 0),
          type_id: "567",
          version_id: "{CBA123-DEF123-GHI456A}",
          series_id: "{CBA321-DEF123-GHI456A}",
          mime_type: "application/pdf"
        )
      ]
    end

    it "should be determined on the amount of unproccesed documents" do
      expect(subject).to eq "less than 5 seconds"
    end
  end

  context "#seconds_left" do
    let(:manifest) { Manifest.create(file_number: "1234") }

    subject { manifest.seconds_left }

    let!(:records) do
      [
        manifest.vbms_source.records.create(
          received_at: Time.utc(2015, 1, 3, 17, 0, 0),
          type_id: "123",
          status: :success,
          version_id: "{ABC123-DEF123-GHI456A}",
          series_id: "{ABC321-DEF123-GHI456A}",
          mime_type: "application/pdf"
        ),
        manifest.vva_source.records.create(
          received_at: Time.utc(2017, 1, 3, 17, 0, 0),
          type_id: "345",
          version_id: "{FDC123-DEF123-GHI456A}",
          series_id: "{KYC321-DEF123-GHI456A}",
          mime_type: "application/pdf"
        ),
        manifest.vbms_source.records.create(
          received_at: Time.utc(2016, 1, 3, 17, 0, 0),
          type_id: "567",
          version_id: "{CBA123-DEF123-GHI456A}",
          series_id: "{CBA321-DEF123-GHI456A}",
          mime_type: "application/pdf"
        )
      ]
    end

    it "should be determined on the amount of unproccesed documents" do
      expect(subject).to eq 4
    end
  end

  context "#zip_expiration_date" do
    let(:manifest) { Manifest.create(file_number: "1234") }
    subject { manifest.zip_expiration_date }

    context "when there is no record of files download" do
      let!(:current_user) { User.authenticate!(roles: ["Reader"]) }
      it { is_expected.to eq nil }
    end

    context "when there is no current user" do
      let!(:current_user) { User.unauthenticate! }
      it { is_expected.to eq nil }
    end

    context "when there is a record of files download" do
      let!(:current_user) { User.authenticate!(roles: ["Reader"]) }
      let!(:files_download) { FilesDownload.create(manifest: manifest, user: current_user, requested_zip_at: 14.hours.ago) }
      it { is_expected.to eq "12/05" }
    end
  end

  context "#recently_downloaded_files?" do
    let(:manifest) { Manifest.create(file_number: "1234") }

    subject { manifest.recently_downloaded_files? }

    context "when recently downloaded files" do
      before do
        manifest.update(fetched_files_status: :finished, fetched_files_at: 2.hours.ago)
      end
      it { is_expected.to be_truthy }
    end

    context "when downloaded a while ago" do
      before do
        manifest.update(fetched_files_status: :finished, fetched_files_at: 12.hours.ago)
      end
      it { is_expected.to be_falsy }
    end

    context "when failed due to an error" do
      before do
        manifest.update(fetched_files_status: :failed)
      end
      it { is_expected.to be_falsy }
    end

    context "when never downloaded files" do
      it { is_expected.to be_falsy }
    end
  end

  context "#records" do
    let(:manifest) { Manifest.create(file_number: "1234") }
    subject { manifest.records }

    let!(:records) do
      [
        manifest.vbms_source.records.create(
          received_at: Time.utc(2015, 1, 3, 17, 0, 0),
          type_id: "123",
          version_id: "{ABC123-DEF123-GHI456A}",
          series_id: "{ABC321-DEF123-GHI456A}",
          mime_type: "application/pdf"
        ),
        manifest.vva_source.records.create(
          received_at: Time.utc(2017, 1, 3, 17, 0, 0),
          type_id: "345",
          version_id: "{FDC123-DEF123-GHI456A}",
          series_id: "{KYC321-DEF123-GHI456A}",
          mime_type: "application/pdf"
        ),
        manifest.vbms_source.records.create(
          received_at: Time.utc(2016, 1, 3, 17, 0, 0),
          type_id: "567",
          version_id: "{CBA123-DEF123-GHI456A}",
          series_id: "{CBA321-DEF123-GHI456A}",
          mime_type: "application/pdf"
        )
      ]
    end
    it "should be ordered by the received_at date" do
      expect(subject[0].type_id).to eq "345"
      expect(subject[1].type_id).to eq "567"
      expect(subject[2].type_id).to eq "123"
    end
  end

  context ".find_or_create_by_user" do
    let(:user) { User.create(css_id: "Foo", station_id: "112") }
    subject { Manifest.find_or_create_by_user(user: user, file_number: "1234") }

    it "creates manifest and user manifest records" do
      subject
      manifest = Manifest.first
      files_download = FilesDownload.first
      expect(manifest.file_number).to eq "1234"
      expect(files_download.user).to eq user
      expect(files_download.manifest).to eq manifest

      Manifest.find_or_create_by_user(user: user, file_number: "1234")
      expect(Manifest.count).to eq 1
      expect(FilesDownload.count).to eq 1
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
