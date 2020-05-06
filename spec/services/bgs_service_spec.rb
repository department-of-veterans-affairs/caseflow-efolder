describe ExternalApi::BGSService do
  include POAMapper

  before do
    RequestStore[:current_user] = User.new(css_id: "RADIOHEAD", station_id: "203")
  end

  let(:bgs_service) { ExternalApi::BGSService.new(client: bgs_client) }
  let(:bgs_veteran_service) { double("veteran") }
  let(:bgs_people_service) { double("people") }
  let(:bgs_security_service) { double("security") }
  let(:bgs_org_service) { double("org") }
  let(:bgs_claimants_service) { double("claimants") }
  let(:bgs_benefit_claims_service) { double("benefit_claims") }
  let(:bgs_client) { double("BGS::Services") }
  let(:file_number) { "666001234" }
  let(:participant_id) { "123" }
  let(:spouse_participant_id) { "456" }
  let(:pids) { [participant_id] }
  let(:bgs_org_poa_response) do
    {
      file_number: "071-claimant-appeal-file-number",
      ptcpnt_id: participant_id,
      power_of_attorney: {
        legacy_poa_cd: "071",
        nm: "PARALYZED VETERANS OF AMERICA, INC.",
        org_type_nm: "POA National Organization",
        ptcpnt_id: "123456"
      }
    }
  end
  let(:bgs_claimants_poa_response) do
    {
      person_org_name: "PARALYZED VETERANS OF AMERICA, INC.",
      person_org_ptcpnt_id: "123456",
      person_organization_name: "POA Attorney",
      relationship_name: "Power of Attorney For",
      veteran_ptcpnt_id: participant_id
    }
  end
  let(:bgs_person_response) do
    {
      first_nm: "Foo",
      last_nm: "Bar",
      brthdy_dt: "1972-03-29",
      file_nbr: "00001234"
    }
  end
  let(:ssn) { "123-43-1111" }
  let(:css_id) { "AUSER" }
  let(:station_id) { "283" }
  let(:bgs_css_user_profile_response) do
    {
      :appl_role=>"User", :bdn_num=>"1002", :email_address=>"caseflow@example.com",
      :file_num=>nil, :first_name=>"TEST", :functions=>[
        {:assigned_value=>"NO", :disable_ind=>"N", :name=>"Download eFolder"},
        {:assigned_value=>"NO", :disable_ind=>"N", :name=>"System Admin"}
      ],
      :job_title=>"Example Review Officer", :last_name=>"ONE", :message=>"Success", :middle_name=>nil, :participant_id=>"123"
    }
  end
  let(:bgs_css_user_stations_response) do
    {
      :network_login_name=>"AUSER",
      :user_application=>"CASEFLOW",
      :user_stations=>{:enabled=>true, :id=>"283", :name=>"Hines SDC", :role=>"User"}
    }
  end
  let(:bgs_benefit_claims_response) do
    [
      {
        :payee_type_cd=>"10",
        :payee_type_nm=>"Spouse",
        :pgm_type_cd=>"CPD",
        :pgm_type_nm=>"Compensation-Pension Death",
        :ptcpnt_clmant_id=> spouse_participant_id,
        :ptcpnt_vet_id=> participant_id,
        :status_type_nm=>"Cleared"
      }
    ]
  end

  before do
    allow(ExternalApi::BGSService).to receive(:init_client) { bgs_client }
    allow(bgs_client).to receive(:org) { bgs_org_service }
    allow(bgs_client).to receive(:people) { bgs_people_service }
    allow(bgs_client).to receive(:veteran) { bgs_veteran_service }
    allow(bgs_client).to receive(:claimants) { bgs_claimants_service }
    allow(bgs_client).to receive(:common_security) { bgs_security_service }
    allow(bgs_client).to receive(:benefit_claims) { bgs_benefit_claims_service }
    allow(bgs_org_service).to receive(:find_poas_by_file_number).with(file_number) { bgs_org_poa_response }
    allow(bgs_claimants_service).to receive(:find_poa_by_file_number).with(file_number) { bgs_claimants_poa_response }
    allow(bgs_claimants_service).to receive(:find_poa_by_participant_id).with(participant_id) { bgs_claimants_poa_response }
    allow(bgs_org_service).to receive(:find_poas_by_ptcpnt_ids).with(pids) { bgs_org_poa_response }
    allow(bgs_veteran_service).to receive(:find_by_file_number).with(file_number) { bgs_veteran_response }
    allow(bgs_people_service).to receive(:find_person_by_ptcpnt_id).with(participant_id) { bgs_person_response }
    allow(bgs_people_service).to receive(:find_by_ssn).with(ssn) { bgs_person_response }
    allow(bgs_security_service).to receive(:get_css_user_stations).with(css_id) { bgs_css_user_stations_response }
    allow(bgs_security_service).to receive(:get_security_profile)
      .with(username: css_id, station_id: station_id, application: "CASEFLOW") { bgs_css_user_profile_response }
    allow(bgs_benefit_claims_service).to receive(:find_claim_by_file_number).with(file_number) { bgs_benefit_claims_response }
  end

  context "#parse_veteran_info" do
    before do
      @veteran_data = {
        ssn: ssn,
        first_name: "FirstName",
        last_name: "LastName"
      }
    end

    context "if bgs service returns a string ssn" do
      subject { bgs_service.parse_veteran_info(@veteran_data)["veteran_last_four_ssn"] }
      it { is_expected.to eq("1111") }
    end

    context "if bgs service returns no ssn in VetBirlsRecod, but it does in vetCorpRecord" do
      veteran_data = {
        ssn: nil,
        soc_sec_number: "43214321"
      }
      subject { bgs_service.parse_veteran_info(veteran_data)["veteran_last_four_ssn"] }
      it { is_expected.to eq("4321") }
    end

    context "if bgs service returns last name" do
      subject { bgs_service.parse_veteran_info(@veteran_data)["veteran_last_name"] }
      it { is_expected.to eq("LastName") }
    end

    context "if bgs service returns first name" do
      subject { bgs_service.parse_veteran_info(@veteran_data)["veteran_first_name"] }
      it { is_expected.to eq("FirstName") }
    end
  end

  context "#valid_file_number?" do
    subject { bgs_service.valid_file_number?(file_number) }

    context "when valid" do
      let(:file_number) { "123456789" }
      it { is_expected.to eq true }
    end

    context "when not a number" do
      let(:file_number) { "123K456789" }
      it { is_expected.to eq false }
    end

    context "when longer than 9 chars" do
      let(:file_number) { "1234567891" }
      it { is_expected.to eq false }
    end

    context "when shorter than 8 char" do
      let(:file_number) { "456789" }
      it { is_expected.to eq false }
    end
  end

  context "#record_found?" do
    subject { bgs_service.record_found?(veteran_info) }

    context "when found with no file/claim/ssn" do
      let(:veteran_info) { { "return_message" => "BPNQ0301" } }
      it { is_expected.to eq false }
    end

    context "when found with file or claim" do
      let(:veteran_info) { { "return_message" => "BPNQ0301", "file_number" => "1234" } }
      it { is_expected.to eq true }
    end

    context "when found with ssn" do
      let(:veteran_info) { { "return_message" => "BPNQ0301", "veteran_last_four_ssn" => "1234" } }
      it { is_expected.to eq true }
    end

    context "when not found" do
      let(:veteran_info) { { "return_message" => "No BIRLS record found" } }
      it { is_expected.to eq false }
    end
  end

  context "#fetch_person_by_ssn" do
    subject { bgs_service.fetch_person_by_ssn(ssn) }

    it "returns Person info" do
      expect(subject[:first_name]).to eq "Foo"
    end
  end

  context "#fetch_person_info" do
    subject { bgs_service.fetch_person_info(participant_id) }

    it "returns Person info" do
      expect(subject[:first_name]).to eq "Foo"
    end
  end

  context "#fetch_poas_by_participant_ids" do
    subject { bgs_service.fetch_poas_by_participant_ids(pids) }

    it "returns POA info" do
      expect(subject[participant_id][:representative_name]).to eq "PARALYZED VETERANS OF AMERICA, INC."
    end
  end

  context "#fetch_poa_by_file_number" do
    subject { bgs_service.fetch_poa_by_file_number(file_number) }

    it "returns POA info" do
      expect(subject[:representative_name]).to eq "PARALYZED VETERANS OF AMERICA, INC."
    end
  end

  context "#fetch_poa_by_participant_id" do
    subject { bgs_service.fetch_poa_by_participant_id(participant_id) }

    it "returns POA info" do
      expect(subject[:representative_name]).to eq "PARALYZED VETERANS OF AMERICA, INC."
    end
  end

  context "#fetch_user_info" do
    subject { bgs_service.fetch_user_info(css_id, station_id) }

    it "returns User hash summary" do
      user = subject
      expect(user[:css_id]).to eq css_id
      expect(user[:station_id]).to eq station_id
      expect(user[:email]).to eq "caseflow@example.com"
    end
  end

  context "#fetch_claims_for_file_number" do
    subject { bgs_service.fetch_claims_for_file_number(file_number) }

    it "returns array of claims" do
      expect(subject).to be_a Array
      expect(subject.first[:ptcpnt_clmant_id]).to eq spouse_participant_id
    end
  end
end
