describe GetDownloadManifestJob do
  context "#perform" do
    let(:user) do
      User.create(
        css_id: "TEST_USER",
        station_id: 283
      )
    end
    let(:download) do
      Download.create(
        user_id: user.id,
        file_number: "21012",
        veteran_first_name: "George",
        veteran_last_name: "Washington"
      )
    end
    let(:document) do
      download.documents.create(
        id: 34,
        document_id: "{3333-3333}",
        received_at: Time.utc(2015, 9, 6, 1, 0, 0),
        type_id: "825",
        mime_type: "application/pdf"
      )
    end

    before do
      Fakes::BGSService.veteran_info = {
        "21011" => {
          "veteran_first_name" => "Stan",
          "veteran_last_name" => "Lee",
          "veteran_last_four_ssn" => "2222"
        }
      }
      Download.bgs_service = Fakes::BGSService
      # Force the creation of document after BGS has been initialized
      document
    end

    it "caches documents" do
      allow(S3Service).to receive(:store_file).and_return(nil)
      CacheFilesJob.perform_now(download)

      expect(S3Service).to have_received(:store_file).with(document.s3_filename, anything)
    end
  end
end
