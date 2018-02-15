describe "File API v1", type: :request do
  # Clear out any authentications from previous tests
  let!(:current_user) do
    User.authenticate!(roles: [])
  end
  let(:user) do
    User.create(
      css_id: "TEST_USER",
      station_id: 283
    )
  end
  let(:veteran_id) { "21012" }
  let(:download) do
    Download.create(
      from_api: true,
      user_id: user.id,
      file_number: veteran_id,
      veteran_first_name: "George",
      veteran_last_name: "Washington"
    )
  end
  let!(:document) do
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
    allow_any_instance_of(Fakes::BGSService).to receive(:sensitive_files).and_return(veteran_id.to_s => false)
    FeatureToggle.enable!(:reader_api)
    FeatureToggle.enable!(:vva_service)
  end

  context "When the file doesn't exist in VBMS or VVA" do
    before do
      allow(VBMSService).to receive(:fetch_documents_for).and_return([])
      allow(VVAService).to receive(:fetch_documents_for).and_return([])
      Timecop.freeze(Time.utc(2015, 1, 1, 17, 0, 0))
    end

    let(:veteran_id) { "21011" }
    let(:document) {}
    let(:response_body) do
      {
        data: {
          id: Download.find_by(file_number: veteran_id).id.to_s,
          type: "file",
          attributes: {
            manifest_fetched_at: nil,
            manifest_vva_fetched_at: "2015-01-01T17:00:00.000Z",
            manifest_vbms_fetched_at: "2015-01-01T17:00:00.000Z",
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
    before do
      Timecop.freeze(Time.utc(2015, 1, 1, 17, 0, 0))
    end

    let(:vva_error) { false }
    let(:vbms_error) { false }
    let(:manifest_fetched_at) { nil }
    let(:manifest_vva_fetched_at) { nil }
    let(:manifest_vbms_fetched_at) { nil }
    let(:response_body) do
      {
        data: {
          id: download.id.to_s,
          type: "file",
          attributes: {
            manifest_fetched_at: manifest_fetched_at,
            manifest_vva_fetched_at: manifest_vva_fetched_at,
            manifest_vbms_fetched_at: manifest_vbms_fetched_at,
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
      let(:manifest_vva_fetched_at) { "2015-01-01T17:00:00.000Z" }

      before do
        allow(VBMSService).to receive(:fetch_documents_for).and_raise(VBMS::ClientError)
      end

      it "returns existing files, a nil manifest_fetched_at, and vbms_error is true" do
        get "/api/v1/files", nil, headers
        expect(response.code).to eq("200")
        expect(response.body).to eq(response_body)
      end

      it "caches the VVA manifest and only fetches from VBMS the second time" do
        get "/api/v1/files", nil, headers

        expect(VBMSService).to receive(:fetch_documents_for).exactly(1).times
        expect(VVAService).to receive(:fetch_documents_for).exactly(0).times
        get "/api/v1/files", nil, headers

        expect(response.code).to eq("200")
        expect(response.body).to eq(response_body)
      end
    end

    context "vva throws a client error" do
      let(:vva_error) { true }
      let(:manifest_vbms_fetched_at) { "2015-01-01T17:00:00.000Z" }

      before do
        allow(VVAService).to receive(:fetch_documents_for).and_raise(VVA::ClientError)
      end

      it "returns existing files, a nil manifest_fetched_at, and vva_error is true" do
        get "/api/v1/files", nil, headers
        expect(response.code).to eq("200")
        expect(response.body).to eq(response_body)
      end

      it "caches the VBMS manifest and doesn't fetch from it again" do
        get "/api/v1/files", nil, headers

        expect(VBMSService).to receive(:fetch_documents_for).exactly(0).times
        expect(VVAService).to receive(:fetch_documents_for).exactly(1).times
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

  context "When headers are missing" do
    context "missing CSS ID" do
      let(:headers) do
        {
          "HTTP_FILE_NUMBER" => veteran_id,
          "HTTP_STATION_ID" => user.station_id,
          "HTTP_AUTHORIZATION" => "Token token=#{token}"
        }
      end

      it "returns 400" do
        get "/api/v1/files", nil, headers
        expect(response.code).to eq("400")
        body = JSON.parse(response.body)
        expect(body["status"]).to match(/missing.+CSS.+ID/)
      end
    end

    context "missing Station ID" do
      let(:headers) do
        {
          "HTTP_FILE_NUMBER" => veteran_id,
          "HTTP_CSS_ID" => user.css_id,
          "HTTP_AUTHORIZATION" => "Token token=#{token}"
        }
      end

      it "returns 400" do
        get "/api/v1/files", nil, headers
        expect(response.code).to eq("400")
        body = JSON.parse(response.body)
        expect(body["status"]).to match(/missing.+Station.+ID/)
      end
    end

    context "missing File Number" do
      let(:headers) do
        {
          "HTTP_STATION_ID" => user.station_id,
          "HTTP_CSS_ID" => user.css_id,
          "HTTP_AUTHORIZATION" => "Token token=#{token}"
        }
      end

      it "returns 400" do
        get "/api/v1/files", nil, headers
        expect(response.code).to eq("400")
        body = JSON.parse(response.body)
        expect(body["status"]).to match(/missing.+File.+Number/)
      end
    end
  end

  context "When sensitivity is higher than permissions" do
    before do
      allow_any_instance_of(Fakes::BGSService).to receive(:sensitive_files).and_return(veteran_id.to_s => true)
    end

    it "returns 403" do
      get "/api/v1/files", nil, headers
      expect(response.code).to eq("403")
      body = JSON.parse(response.body)
      expect(body["status"]).to match(/sensitive/)
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
              manifest_vva_fetched_at: "2015-01-01T17:00:00.000Z",
              manifest_vbms_fetched_at: "2015-01-01T17:00:00.000Z",
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

      it "doesn't download files added within 3 hours of calling the endpoint" do
        get "/api/v1/files", nil, headers

        expect(VBMSService).to receive(:fetch_documents_for).exactly(0).times

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
