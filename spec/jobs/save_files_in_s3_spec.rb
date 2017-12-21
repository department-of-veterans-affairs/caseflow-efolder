describe SaveFilesInS3Job do
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
    let(:document_id) do
      "{#{random_int_of_length(4)}-#{random_int_of_length(4)}}"
    end
    let!(:document) do
      download.documents.create(
        id: 34,
        document_id: document_id,
        received_at: Time.utc(2015, 9, 6, 1, 0, 0),
        type_id: "825",
        mime_type: "application/pdf"
      )
    end
    let(:veteran_info) do
      {
        "21011" => {
          "veteran_first_name" => "Stan",
          "veteran_last_name" => "Lee",
          "veteran_last_four_ssn" => "2222"
        }
      }
    end

    before { allow_any_instance_of(Fakes::BGSService).to receive(:veteran_info).and_return(veteran_info) }

    it "saves files in S3" do
      allow(S3Service).to receive(:store_file).and_return(nil)
      SaveFilesInS3Job.perform_now(download)

      expect(S3Service).to have_received(:store_file).with(document.s3_filename, anything)
    end
  end
end

def random_int_of_length(len = 8)
  (Array.new(len) { ("0".."9").to_a.sample }).join
end
