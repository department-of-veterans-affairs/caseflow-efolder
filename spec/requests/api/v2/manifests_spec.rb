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
    m = Manifest.find_or_create_by_user(user: user, file_number: veteran_id)
    m.update(veteran_first_name: "George", veteran_last_name: "Washington")
    m
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
    let(:manifest1) { Manifest.find_or_create_by!(file_number: "123C") }
    let(:manifest2) { Manifest.find_or_create_by!(file_number: "567C") }
    let(:manifest3) { Manifest.find_or_create_by!(file_number: "897C") }
    let(:manifest4) { Manifest.find_or_create_by!(file_number: "935C") }

    let(:another_user) { User.create(css_id: "123C", station_id: "123") }
    let!(:files_download1) { FilesDownload.create(manifest: manifest1, user: user, requested_zip_at: 2.days.ago) }
    let!(:files_download2) { FilesDownload.create(manifest: manifest2, user: another_user, requested_zip_at: 2.days.ago) }
    let!(:files_download3) { FilesDownload.create(manifest: manifest3, user: user) }
    let!(:files_download4) { FilesDownload.create(manifest: manifest2, user: user, requested_zip_at: 5.days.ago) }
    let!(:files_download5) { FilesDownload.create(manifest: manifest4, user: user, requested_zip_at: 1.day.ago) }

    it "returns user's download history" do
      get "/api/v2/manifests/history", params: nil, headers: headers
      expect(response.code).to eq("200")
      response_body = JSON.parse(response.body)["data"]
      expect(response_body.class).to eq Array
      expect(response_body.size).to eq 2
      # should be sorted
      expect(response_body.first["id"]).to eq manifest4.id.to_s
      expect(response_body.second["id"]).to eq manifest1.id.to_s
    end
  end

  context "When more than one BGS Veteran record matches the file number" do
    before do
      allow_any_instance_of(Fakes::BGSService).to receive(:veteran_info).and_return(veteran_info)
      allow_any_instance_of(VeteranFinder).to receive(:find) { [ { file: veteran_claim_number }, { file: veteran_ssn } ] }
      allow(VBMSService).to receive(:v2_fetch_documents_for).with(veteran_claim_number) { documents }
      allow(VBMSService).to receive(:v2_fetch_documents_for).with(veteran_ssn) { documents }
      allow(VBMSService).to receive(:v2_fetch_documents_for).with(veteran_id) { documents }
      allow(VVAService).to receive(:v2_fetch_documents_for) { documents }
    end

    # not a let() because we do not want to memoize the document_id values
    def documents
      [
        OpenStruct.new(
          document_id: SecureRandom.base64,
          series_id: "1234",
          type_id: Caseflow::DocumentTypes::TYPES.keys.sample,
          version: "1",
          mime_type: "txt",
          received_at: Time.now.utc
        ),
        OpenStruct.new(
          document_id: SecureRandom.base64,
          series_id: "5678",
          type_id: Caseflow::DocumentTypes::TYPES.keys.sample,
          version: "1",
          mime_type: "txt",
          received_at: Time.now.utc
        )
      ]
    end

    let(:veteran_record) do
      {
        "veteran_first_name" => "Bob",
        "veteran_last_name" => "Marley",
        "veteran_last_four_ssn" => "1234",
        "return_message" => "BPNQ0301",
      }
    end
    let(:veteran_claim_number) { "12345678" }
    let(:veteran_ssn) { "666001234" }
    let(:veteran_info) do
      {
        veteran_claim_number => veteran_record,
        veteran_ssn          => veteran_record
      }
    end

    it "checks all the efolder records" do
      perform_enqueued_jobs do
        post "/api/v2/manifests", params: nil, headers: headers
        expect(response.code).to eq("200")

        # once for each "file number"
        expect(VBMSService).to have_received(:v2_fetch_documents_for).exactly(3).times
        expect(VVAService).to have_received(:v2_fetch_documents_for).exactly(3).times

        got_body = JSON.parse(response.body, symbolize_names: true)
        got_records = got_body.dig(:data, :attributes, :records)

        expect(got_records.size).to eq(12) # 2 sources * 2 documents * 3 veteran file numbers
      end
    end
  end

  context "When the manifest has no records" do
    before do
      allow(VBMSService).to receive(:v2_fetch_documents_for).and_return([])
      allow(VVAService).to receive(:v2_fetch_documents_for).and_return([])
    end

    let!(:expected_body) do
      {
        data: {
          id: manifest.id.to_s,
          type: "manifest",
          attributes: {
            veteran_first_name: "George",
            veteran_last_name: "Washington",
            file_number: veteran_id,
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
      }
    end

    it "returns empty array" do
      perform_enqueued_jobs do
        post "/api/v2/manifests", params: nil, headers: headers
        expect(response.code).to eq("200")

        got_body = JSON.parse(response.body, symbolize_names: true)
        expected_sources = expected_body[:data][:attributes].delete(:sources)
        got_sources = got_body[:data][:attributes].delete(:sources)

        expect(got_body).to eq(expected_body)
        expect(got_sources).to contain_exactly(*expected_sources)
      end
    end
  end

  context "When the incorrect token is passed" do
    let(:token) { "bad token" }

    it "returns 401" do
      get "/api/v2/manifests/#{manifest.id}", params: nil, headers: headers
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
        get "/api/v2/manifests/#{manifest.id}", params: nil, headers: headers
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
        get "/api/v2/manifests/#{manifest.id}", params: nil, headers: headers
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

      it "returns 200" do
        get "/api/v2/manifests/#{manifest.id}", params: nil, headers: headers
        expect(response.code).to eq("200")
      end
    end

    context "invalid manifest ID" do
      let(:invalid_manifest_id) { 123 }

      it "returns 404" do
        get "/api/v2/manifests/#{invalid_manifest_id}", params: nil, headers: headers
        expect(response.code).to eq("404")
        body = JSON.parse(response.body)
        expect(body["errors"][0]["detail"]).to match(/A record with that ID was not found in our systems/)
      end
    end
  end

  context "When sensitivity is higher than permissions" do
    let(:veteran_id) { "DEMO456" }

    before do
      allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info).and_raise("Sensitive File - Access Violation")
    end

    it "returns 403" do
      post "/api/v2/manifests/", params: nil, headers: headers
      expect(response.code).to eq("403")
      body = JSON.parse(response.body)
      expect(body["status"]).to match(/sensitive/)
    end
  end

  context "When user does not exist in BGS" do
    let(:error_string) { "Logon ID VACOHSOLO Not Found in the Benefits Gateway Service (BGS). Contact your ISO if you need assistance gaining access to BGS." }
    before do
      allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info).and_raise(BGS::PublicError.new(error_string))
    end

    it "returns 403 forbidden response" do
      post "/api/v2/manifests/", params: nil, headers: headers
      expect(response.code).to eq("403")
      body = JSON.parse(response.body)
      expect(body["status"]).to eq(error_string)
    end
  end

  context "When file number is not found in BGS" do
    let(:veteran_id) { "40400000" }
    let(:error_string) { "eFolder Express could not find an eFolder with the Veteran ID 40400000. Check to make sure you entered the ID correctly and try again." }

    it "returns a 400 with not found message" do
      perform_enqueued_jobs do
        post "/api/v2/manifests", params: nil, headers: headers
        expect(response.code).to eq("400")
        body = JSON.parse(response.body)
        expect(body["status"]).to eq(error_string)
      end
    end
  end

  context "POA" do
    before { FeatureToggle.enable!(:user_authorizer) }
    after { FeatureToggle.disable!(:user_authorizer) }

    subject { post "/api/v2/manifests/", params: nil, headers: headers }

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
    let(:claimants_poa_response) do
      {
        representative_name: "A Lawyer",
        participant_id: poa_participant_id,
        representative_type: "POA Attorney",
        veteran_participant_id: veteran_participant_id
      }
    end
    let(:benefit_claims_response) do
      [
        {
          payee_type_cd: "10",
          payee_type_nm: "Spouse",
          pgm_type_cd: "CPD",
          pgm_type_nm: "Compensation-Pension Death",
          ptcpnt_clmant_id: claimant_participant_id,
          ptcpnt_vet_id: veteran_participant_id,
          status_type_nm: "Cleared"
        }
      ]
    end

    let(:body) { JSON.parse(response.body, symbolize_names: true) }

    context "user is VSO" do
      let!(:user) do
        user = User.create(css_id: "VSO", station_id: "283", participant_id: poa_participant_id)
        RequestStore.store[:current_user] = user
      end

      context "user does not have POA for Veteran" do
        before do
          allow_any_instance_of(BGSService).to receive(:fetch_veteran_info).with(veteran_id) do |bgs|
            if bgs.client.css_id == User.system_user.css_id
              bgs.parse_veteran_info(veteran_info)
            else
              raise BGS::ShareError.new("Power of Attorney of Folder is none")
            end
          end
          allow_any_instance_of(BGSService).to receive(:fetch_poa_by_file_number)
            .with(veteran_id) { nil }
        end

        it "responds with error" do
          subject

          expect(response).to_not be_successful
          expect(body[:status]).to include("This efolder belongs to a Veteran you do not represent")
        end

        context "Veteran is deceased" do
          let(:veteran_date_of_death) { "2020/03/29" }

          context "user has POA for Claimant" do
            before do
              allow_any_instance_of(BGSService).to receive(:fetch_poa_by_participant_id)
                .with(claimant_participant_id) { claimants_poa_response }
              allow_any_instance_of(BGSService).to receive(:fetch_claims_for_file_number)
                .with(veteran_id) { benefit_claims_response }
            end

            it "responds with success" do
              subject

              expect(response).to be_successful
              expect(body[:data]).to_not be_nil
              expect(body.dig(:data, :attributes, :veteran_last_name)).to eq veteran_info[:last_name]
            end
          end

          context "user does not have POA for Claimant" do
            before do
              allow_any_instance_of(BGSService).to receive(:fetch_poa_by_participant_id)
                .with(claimant_participant_id) { nil }
            end

            it "responds with error" do
              subject

              expect(response).to_not be_successful
              expect(body[:status]).to include("This efolder belongs to a Veteran you do not represent")
            end
          end
        end
      end

      context "user does not have POA for Veteran record but does have POA via BGS claimants" do
        before do
          allow_any_instance_of(BGSService).to receive(:fetch_veteran_info).with(veteran_id) do |bgs|
            if bgs.client.css_id == User.system_user.css_id
              bgs.parse_veteran_info(veteran_info)
            else
              raise BGS::ShareError.new("Power of Attorney of Folder is none")
            end
          end
          allow_any_instance_of(BGSService).to receive(:fetch_poa_by_file_number)
            .with(veteran_id) { claimants_poa_response }
        end

        it "responds with success" do
          subject

          expect(response).to be_successful
          expect(body.dig(:data)).to_not be_nil
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
          subject

          expect(response).to_not be_successful
          expect(body[:status]).to include("This efolder contains sensitive information")
        end
      end
    end
  end
end
