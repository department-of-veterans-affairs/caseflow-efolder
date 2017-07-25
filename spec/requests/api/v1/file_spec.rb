describe "File API v1", type: :request do
  let(:user) do
    User.create(
      css_id: "TEST_USER",
      station_id: 283
    )
  end
  let(:veteran_id) { "21012" }
  let(:download) do
    Download.create(
      user_id: user.id,
      file_number: veteran_id,
      veteran_first_name: "George",
      veteran_last_name: "Washington"
    )
  end
  let(:document) do
    download.documents.create(
      document_id: "{3333-3333}",
      received_at: Time.utc(2015, 9, 6, 1, 0, 0),
      type_id: "825",
      mime_type: "application/pdf"
    )
  end
  let(:token) do
    "token"
  end
  let(:headers) do
    {
      "HTTP_FILE_NUMBER" => veteran_id,
      "HTTP_CSS_ID" => user.css_id,
      "HTTP_STATION_ID" => user.station_id,
      "HTTP_AUTHORIZATION" => "Token token=#{token}"
    }
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

    let(:veteran_id) { "21011" }
    let(:document) {}
    let(:response_body) do
      {
        data: {
          id: download.id.to_s,
          type: "file",
          attributes: {
            manifest_fetched_at: nil,
            vbms_error: false,
            vva_error: false,
            documents: []
          }
        }
      }.to_json
    end

    it "returns empty array" do
      get "/api/v1/files", nil, headers
      expect(response.code).to eq("200")
      expect(response.body).to eq(response_body)
    end
  end

  context "When a dependency throws an error" do
    let(:vva_error) { false }
    let(:vbms_error) { false }
    let(:response_body) do
      {
        data: {
          id: download.id.to_s,
          type: "file",
          attributes: {
            manifest_fetched_at: nil,
            vbms_error: vbms_error,
            vva_error: vva_error,
            documents: [{
              id: document.id,
              type_id: "825",
              received_at: "2015-09-06T01:00:00.000Z",
              external_document_id: document.document_id
            }]
          }
        }
      }.to_json
    end

    context "vbms throws a client error" do
      let(:vbms_error) { true }

      before do
        allow(VBMSService).to receive(:fetch_documents_for).and_raise(VBMS::ClientError)
      end

      it "returns existing files, a nil manifest_fetched_at, and vbms_error is true" do
        get "/api/v1/files", nil, headers
        expect(response.code).to eq("200")
        expect(response.body).to eq(response_body)
      end
    end

    context "vva throws a client error" do
      let(:vva_error) { true }

      before do
        allow(VVAService).to receive(:fetch_documents_for).and_raise(VVA::ClientError)
      end

      it "returns existing files, a nil manifest_fetched_at, and vva_error is true" do
        get "/api/v1/files", nil, headers
        expect(response.code).to eq("200")
        expect(response.body).to eq(response_body)
      end
    end
  end

  context "When the incorrect token is passed" do
    let(:token) { "bad token" }

    it "returns 401" do
      get "/api/v1/files", nil, headers
      expect(response.code).to eq("401")
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
        Timecop.freeze(Time.utc(2015, 1, 1, 17, 0, 0))
        download.update_attributes!(manifest_fetched_at: Time.zone.now - 4.hours)
      end

      let(:response_documents) do
        vbms_documents.map do |document|
          {
            document_id: document.document_id,
            type_id: document.type_id,
            received_at: document.received_at.to_datetime
          }
        end
      end

      # We hard code the response so that any changes in the API can be caught.
      let(:response_body) do
        {
          data: {
            id: download.id.to_s,
            type: "file",
            attributes: {
              manifest_fetched_at: "2015-01-01T17:00:00.000Z",
              vbms_error: false,
              vva_error: false,
              documents: [
                {
                  id: download.documents[0].id,
                  type_id: "124",
                  received_at: "2017-04-03T00:00:00.000Z",
                  external_document_id: "2"
                },
                {
                  id: download.documents[1].id,
                  type_id: "123",
                  received_at: "2017-02-01T00:00:00.000Z",
                  external_document_id: "1"
                },
                {
                  id: download.documents[2].id,
                  type_id: "825",
                  received_at: "2015-09-06T01:00:00.000Z",
                  external_document_id: document.document_id
                }
              ]
            }
          }
        }.to_json
      end

      it "returns existing and new files" do
        get "/api/v1/files", nil, headers

        expect(response.code).to eq("200")
        expect(response.body).to eq(response_body)
      end
    end

    context "when the download flag is passed" do
      it "starts the download job" do
        allow(SaveFilesInS3Job).to receive(:perform_later)

        get "/api/v1/files?download=true", nil, headers

        expect(SaveFilesInS3Job).to have_received(:perform_later)
      end
    end
  end
end
