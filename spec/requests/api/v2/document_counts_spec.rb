describe "Document Counts API v2", type: :request do
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
  let(:veteran_id) { "DEMOFAST" }
  let(:token) { "token" }
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
    allow_any_instance_of(Fakes::BGSService).to receive(:record_found?).and_return(true)
    allow_any_instance_of(VeteranFinder).to receive(:find) { [ { file: veteran_id } ] }
    Timecop.freeze(Time.utc(2015, 1, 1, 17, 0, 0))
  end

  describe "#index" do
    it "returns veteran document count" do
      get "/api/v2/document_counts", params: nil, headers: headers

      expect(response.code).to eq("200")

      body = JSON.parse(response.body, symbolize_names: true)

      expect(body[:documents]).to eq(20)
    end
  end
end
