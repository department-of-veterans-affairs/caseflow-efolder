describe "Manifests API v2", type: :request do
  include ActiveJob::TestHelper

  let!(:current_user) do
    User.authenticate!(roles: [])
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
    allow_any_instance_of(Fakes::BGSService).to receive(:sensitive_files).and_return(veteran_id.to_s => false)
    Timecop.freeze(Time.utc(2015, 1, 1, 17, 0, 0))
  end

  context "View download history" do
    let(:manifest1) { Manifest.create(file_number: "123C") }
    let(:manifest2) { Manifest.create(file_number: "567C") }
    let(:manifest3) { Manifest.create(file_number: "897C") }
    let(:manifest4) { Manifest.create(file_number: "935C") }

    let(:another_user) { User.create(css_id: "123C", station_id: "123") }
    let!(:files_download1) { FilesDownload.create(manifest: manifest1, user: user, requested_zip_at: 2.days.ago) }
    let!(:files_download2) { FilesDownload.create(manifest: manifest2, user: another_user, requested_zip_at: 2.days.ago) }
    let!(:files_download3) { FilesDownload.create(manifest: manifest3, user: user) }
    let!(:files_download4) { FilesDownload.create(manifest: manifest2, user: user, requested_zip_at: 5.days.ago) }
    let!(:files_download5) { FilesDownload.create(manifest: manifest4, user: user, requested_zip_at: 1.day.ago) }

    it "returns user's download history" do
      get "/api/v2/manifests/history", nil, headers
      expect(response.code).to eq("200")
      response_body = JSON.parse(response.body)["data"]
      expect(response_body.size).to eq 2
      # should be sorted
      expect(response_body.first["id"]).to eq manifest4.id.to_s
      expect(response_body.second["id"]).to eq manifest1.id.to_s
    end
  end

  context "When the manifest has no records" do
    before do
      allow(VBMSService).to receive(:v2_fetch_documents_for).and_return([])
      allow(VVAService).to receive(:v2_fetch_documents_for).and_return([])
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
            fetched_files_at: nil,
            fetched_files_status: "initialized",
            number_successful_documents: 0,
            number_failed_documents: 0,
            zip_expiration_date: nil,
            time_to_complete: "less than 5 seconds",
            seconds_left: 0,
            sources: [
              {
                source: "VBMS",
                status: "success",
                fetched_at: "2015-01-01T17:00:00.000Z",
                number_of_documents: 0
              },
              {
                source: "VVA",
                status: "success",
                fetched_at: "2015-01-01T17:00:00.000Z",
                number_of_documents: 0
              }
            ],
            records: []
          }
        }
      }.to_json
    end

    it "returns empty array" do
      perform_enqueued_jobs do
        post "/api/v2/manifests", nil, headers
        expect(response.code).to eq("200")
        expect(response.body).to eq(response_body)
      end
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
      allow_any_instance_of(Fakes::BGSService).to receive(:sensitive_files).and_return(veteran_id.to_s => true)
    end

    it "returns 403" do
      get "/api/v2/manifests", nil, headers
      expect(response.code).to eq("403")
      body = JSON.parse(response.body)
      expect(body["status"]).to match(/sensitive/)
    end
  end
end
