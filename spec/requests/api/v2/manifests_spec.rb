describe "Manifests API v2", type: :request do
  let!(:current_user) do
    User.authenticate!
  end
  let(:user) do
    User.create(
      css_id: "TEST_USER",
      station_id: 283
    )
  end
  let(:veteran_id) { "DEMO987" }
  let(:manifest) do
    Manifest.create(
      file_number: veteran_id,
      veteran_first_name: "George",
      veteran_last_name: "Washington"
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
    Fakes::BGSService.sensitive_files = { veteran_id.to_s => false }
    Timecop.freeze(Time.utc(2015, 1, 1, 17, 0, 0))
  end

  context "When the manifest has no records" do
    before do
      allow(VBMSService).to receive(:fetch_documents_for).and_return([])
      allow(VVAService).to receive(:fetch_documents_for).and_return([])
    end

    let!(:response_body) do
      {
        data: {
          id: manifest.id.to_s,
          type: "manifest",
          attributes: {
            veteran_first_name: "George",
            veteran_last_name: "Washington",
            created_at: "2015-01-01T17:00:00.000Z",
            updated_at: "2015-01-01T17:00:00.000Z",
            sources: [
              {
                source: "VBMS",
                status: "success",
                fetched_at: "2015-01-01T17:00:00.000Z"
              },
              {
                source: "VVA",
                status: "success",
                fetched_at: "2015-01-01T17:00:00.000Z"
              }
            ],
            records: []
          }
        }
      }.to_json
    end

    it "returns empty array" do
      get "/api/v2/manifests", nil, headers
      expect(response.code).to eq("200")
      expect(response.body).to eq(response_body)
    end
  end

  context "When the incorrect token is passed" do
    let(:token) { "bad token" }

    it "returns 401" do
      get "/api/v2/manifests", nil, headers
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
        get "/api/v2/manifests", nil, headers
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
        get "/api/v2/manifests", nil, headers
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
        get "/api/v2/manifests", nil, headers
        expect(response.code).to eq("400")
        body = JSON.parse(response.body)
        expect(body["status"]).to match(/missing.+File.+Number/)
      end
    end

    context "invalid File Number" do
      let(:headers) do
        {
          "HTTP_STATION_ID" => user.station_id,
          "HTTP_CSS_ID" => user.css_id,
          "HTTP_AUTHORIZATION" => "Token token=#{token}",
          "HTTP_FILE_NUMBER" => "123"
        }
      end

      it "returns 400" do
        get "/api/v2/manifests", nil, headers
        expect(response.code).to eq("400")
        body = JSON.parse(response.body)
        expect(body["status"]).to match(/File.+Number.+invalid.+must.+8.+9.+digits/)
      end
    end
  end

  context "When sensitivity is higher than permissions" do
    before do
      Fakes::BGSService.sensitive_files = { veteran_id.to_s => true }
    end

    it "returns 403" do
      get "/api/v2/manifests", nil, headers
      expect(response.code).to eq("403")
      body = JSON.parse(response.body)
      expect(body["status"]).to match(/sensitive/)
    end
  end
end
