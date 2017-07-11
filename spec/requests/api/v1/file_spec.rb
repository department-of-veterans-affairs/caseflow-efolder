describe "File API v1", type: :request do
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
    Download.bgs_service = Fakes::BGSService
    # Force the creation of document after BGS has been initialized
    document

    FeatureToggle.enable!(:reader_api)
  end

  context "When the file doesn't exist in VBMS or VVA" do
    before do
      allow(VBMSService).to receive(:fetch_documents_for).and_return([])
      allow(VVAService).to receive(:fetch_documents_for).and_return([])
    end

    it "returns 404 if file ID is not found" do
      get "/api/v1/files/21011?user_id=#{user.id}"
      expect(response.code).to eq("404")
    end
  end

  context "When the file exists in VBMS or VVA" do
    before do
      allow(VVAService).to receive(:fetch_documents_for).and_return([])
      allow(VBMSService).to receive(:fetch_documents_for).and_return(vbms_documents)
    end

    let(:vbms_documents) do
      [
        OpenStruct.new(
          document_id: "1",
          received_at: "1/2/2017",
          type_id: "123"
        ),
        OpenStruct.new(
          document_id: "2",
          received_at: "3/4/2017",
          type_id: "124"
        )
      ]
    end

    context "retrieve the documents" do
      before do
        download.update_attributes!(manifest_fetched_at: Time.zone.now - 4.hours)
      end

      it "returns existing and new files" do
        get "/api/v1/files/#{download.file_number}?user_id=#{user.id}"

        expect(response.code).to eq("200")
        files = JSON.parse(response.body)["data"]["attributes"]["documents"]

        expect(files.size).to eq(3)

        expect(files[0]["document_id"]).to eq(document.document_id)
        expect(files[0]["type_id"]).to eq(document.type_id)
        expect(files[0]["received_at"].to_datetime).to eq(document.received_at)

        expect(files[1]["document_id"]).to eq(vbms_documents[0].document_id)
        expect(files[1]["type_id"]).to eq(vbms_documents[0].type_id)
        expect(files[1]["received_at"].to_datetime).to eq(vbms_documents[0].received_at.to_datetime)
      end
    end

    context "when the download flag is passed" do
      it "starts the download job" do
        allow(SaveFilesInS3Job).to receive(:perform_later)

        get "/api/v1/files/#{download.file_number}?user_id=#{user.id}&download=true"

        expect(SaveFilesInS3Job).to have_received(:perform_later)
      end
    end
  end
end
