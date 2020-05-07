describe Api::V2::ApplicationController do
  controller do
    def index
      file_number = verify_veteran_file_number
      return if performed?

      render json: { status: file_number }, status: :ok
    end
  end

  let!(:user) { User.authenticate! }
  let(:veteran_id) { "DEMO987" }
  let(:token) { "token" }
  let(:headers) do
    {
      "HTTP_FILE_NUMBER" => veteran_id,
      "HTTP_CSS_ID" => user.css_id,
      "HTTP_STATION_ID" => user.station_id,
      "HTTP_AUTHORIZATION" => "Token token=#{token}"
    }
  end
  let(:veteran_info) do
    {
      first_name: "Bob",
      last_name: "Marley",
      ssn: "666001234",
      return_message: "hello world",
      date_of_death: veteran_date_of_death,
      file_number: veteran_id,
      ptcpnt_id: veteran_participant_id
    }
  end
  let(:veteran_date_of_death) { "" }
  let(:veteran_participant_id) { "123" }
  let(:poa_participant_id) { "345" }
  let(:claimant_participant_id) { "456" }
  let(:claimants_poa_fn_response) do
    {
      representative_name: "A Lawyer",
      participant_id: poa_participant_id,
      representative_type: "POA Attorney",
      veteran_participant_id: veteran_participant_id
    }
  end

  let(:body) { JSON.parse(response.body, symbolize_names: true) }

  before do
    FeatureToggle.enable!(:user_authorizer)
  end

  after do
    FeatureToggle.disable!(:user_authorizer)
  end
 
  describe "veteran file number access" do
    before do
      request.headers.merge!(headers)
    end

    it "validates file number" do
      get :index

      expect(response).to be_successful
      expect(body).to eq(status: veteran_id) 
    end

    context "user is VSO" do
      let!(:user) do
        user = User.create(css_id: "VSO", station_id: "283", participant_id: poa_participant_id)
        RequestStore.store[:current_user] = user
      end

      context "user does not have POA" do
        before do
          allow_any_instance_of(BGSService).to receive(:fetch_veteran_info).with(veteran_id) do |bgs|
            if bgs.client.css_id == User.system_user.css_id
              veteran_info
            else
              raise BGS::ShareError.new("Power of Attorney of Folder is none")
            end
          end
          allow_any_instance_of(BGSService).to receive(:fetch_poa_by_file_number)
            .with(veteran_id) { nil }
        end

        it "responds with error" do
          get :index

          expect(response).to_not be_successful
          expect(body[:status]).to include("This efolder belongs to a Veteran you do not represent")
        end

        context "Veteran is deceased" do
          context "Claimant has POA" do
          end

          context "Claimant does not have POA" do
          end
        end
      end

      context "user has POA" do
        before do
          allow_any_instance_of(BGSService).to receive(:fetch_veteran_info).with(veteran_id) do |bgs|
            if bgs.client.css_id == User.system_user.css_id
              bgs.parse_veteran_info(veteran_info)
            else
              raise BGS::ShareError.new("Power of Attorney of Folder is none")
            end
          end
          allow_any_instance_of(BGSService).to receive(:fetch_poa_by_file_number)
            .with(veteran_id) { claimants_poa_fn_response }
        end

        it "responds with success" do
          get :index

          expect(response).to be_successful
          expect(body).to eq(status: veteran_id)
        end
      end

      context "Veteran record is sensitive" do
        before do
          allow_any_instance_of(BGSService).to receive(:fetch_veteran_info).with(veteran_id) do |bgs|
            if bgs.client.css_id == User.system_user.css_id
              bgs.parse_veteran_info(veteran_info)
            else
              raise BGS::ShareError.new("Sensitive File - Access Violation")
            end
          end
        end

        it "responds with error" do
          get :index

          expect(response).to_not be_successful
          expect(body[:status]).to include("This efolder contains sensitive information")
        end
      end
    end
  end
end
