# frozen_string_literal: true

describe UserAuthorizer do
  let(:roles) { ["Download eFolder"] }
  let(:file_number) { "66660000" }
  let(:veteran_participant_id) { "1234" }
  let(:claimant_participant_id) { "5678" }
  let(:bva_participant_id) { "123" }
  let(:poa_participant_id) { "456" }
  let(:bva_user) do
    User.new(
      participant_id: bva_participant_id,
      css_id: "BVAUSER",
      station_id: "101",
      roles: roles,
      name: "Board Judge",
      email: "judge@example.com"
    )
  end
  let(:poa_user) do
    User.new(
      participant_id: poa_participant_id,
      css_id: "IAMPOA",
      email: "poa@example.com",
      name: "A Lawyer", 
      roles: roles,
      station_id: "213"
    )
  end
  let(:css_id) { user.css_id }
  let(:station_id) { user.station_id }
  let(:bgs_service) { ExternalApi::BGSService.new(client: bgs_client) }
  let(:system_bgs_service) { ExternalApi::BGSService.new(client: system_bgs_client) }
  let(:bgs_veteran_service) { double("veteran") }
  let(:system_bgs_veteran_service) { double("veteran") }
  let(:bgs_people_service) { double("people") }
  let(:bgs_security_service) { double("security") }
  let(:bgs_org_service) { double("org") }
  let(:bgs_claimants_service) { double("claimants") }
  let(:bgs_benefit_claims_service) { double("benefit_claims") }
  let(:bgs_client) { double("BGS::Services") }
  let(:system_bgs_client) { double("BGS::Services") }
  let(:bgs_claimants_poa_fn_response) do
    {
      person_org_name: "A Lawyer",
      person_org_ptcpnt_id: poa_participant_id,
      person_organization_name: "POA Attorney",
      relationship_name: "Power of Attorney For",
      veteran_ptcpnt_id: veteran_participant_id
    }
  end
  let(:bgs_claimants_poa_pid_response) do
    {
      person_org_name: "A Lawyer",
      person_org_ptcpnt_id: poa_participant_id,
      person_organization_name: "POA Attorney",
      relationship_name: "Power of Attorney For",
      veteran_ptcpnt_id: veteran_participant_id
    }
  end
  let(:bgs_css_user_profile_response) do
    {
      participant_id: user.participant_id
    }
  end
  let(:bgs_benefit_claims_response) do
    [
      {
        :payee_type_cd=>"10",
        :payee_type_nm=>"Spouse",
        :pgm_type_cd=>"CPD",
        :pgm_type_nm=>"Compensation-Pension Death",
        :ptcpnt_clmant_id=> claimant_participant_id,
        :ptcpnt_vet_id=> veteran_participant_id,
        :status_type_nm=>"Cleared"
      }
    ]
  end
  let(:bgs_veteran_response) do
    {
      first_name: "Bob",
      last_name: "Marley",
      ssn: "666001234",
      return_message: "hello world",
      date_of_death: veteran_date_of_death,
      file_number: file_number,
      ptcpnt_id: veteran_participant_id
    }
  end
  let(:veteran_date_of_death) { "" }
  let(:authorizer) { described_class.new(user: user, file_number: file_number) }

  before do
    allow(authorizer).to receive(:bgs) { bgs_service }
    allow(authorizer).to receive(:system_bgs) { system_bgs_service }
    #allow(ExternalApi::BGSService).to receive(:init_client) { bgs_client }
    allow(bgs_client).to receive(:veteran) { bgs_veteran_service }
    allow(system_bgs_client).to receive(:veteran) { system_bgs_veteran_service }
    allow(bgs_client).to receive(:claimants) { bgs_claimants_service }
    allow(bgs_client).to receive(:common_security) { bgs_security_service }
    allow(bgs_client).to receive(:benefit_claims) { bgs_benefit_claims_service }
    allow(bgs_claimants_service).to receive(:find_poa_by_file_number).with(file_number) { bgs_claimants_poa_fn_response }
    allow(bgs_claimants_service).to receive(:find_poa_by_participant_id).with(claimant_participant_id) { bgs_claimants_poa_pid_response }
    allow(bgs_veteran_service).to receive(:find_by_file_number).with(file_number) { bgs_veteran_response }
    allow(system_bgs_veteran_service).to receive(:find_by_file_number).with(file_number) { bgs_veteran_response }
    allow(bgs_security_service).to receive(:get_security_profile)
      .with(username: css_id, station_id: station_id, application: "CASEFLOW") { bgs_css_user_profile_response }
    allow(bgs_benefit_claims_service).to receive(:find_claim_by_file_number).with(file_number) { bgs_benefit_claims_response }
  end

  describe "#new" do
    let(:user) { bva_user }
    subject { authorizer }

    it "reads user and file number" do
      expect(subject.user).to eq bva_user
      expect(subject.file_number).to eq file_number
    end
  end

  describe "#can_read_efolder?" do
    subject { authorizer.can_read_efolder? }

    context "BVA user" do
      let(:user) { bva_user }

      it "returns true" do
        expect(subject).to eq true
      end

      context "sensitivity error" do
        before do
          allow(bgs_veteran_service).to receive(:find_by_file_number)
            .with(file_number).and_raise(BGS::ShareError.new("Sensitive File - Access Violation"))
        end

        it "returns false" do
          expect(subject).to eq false
          expect(authorizer.sensitive_file).to eq true
        end
      end
    end

    context "POA user" do
      let(:user) { poa_user }

      context "veteran is alive" do
        context "has POA for veteran" do
          it "returns true" do
          end
        end
      end

      context "veteran is deceased" do
        let(:veteran_date_of_death) { "2020/03/29" }

        context "has POA for veteran" do
          it "returns true" do
            expect(subject).to eq true
          end
        end

        context "does not have POA for veteran" do
          before do
            allow(bgs_veteran_service).to receive(:find_by_file_number)
              .with(file_number).and_raise(BGS::ShareError.new("Power of Attorney of Folder is none"))
          end

          let(:bgs_claimants_poa_fn_response) { nil } # what BGS returns if no POA is found

          context "does not have POA for claimant" do
            let(:bgs_claimants_poa_pid_response) { nil }

            it "returns false" do
              expect(subject).to eq false
              expect(authorizer.poa_denied).to eq true
              expect(authorizer.veteran_poa?).to eq false
              expect(authorizer.claimant_poa?).to eq false
              expect(authorizer.veteran_deceased?).to eq true
              expect(authorizer.sensitive_file).to be_falsey
            end
          end

          context "has POA for claimant" do
            it "returns true" do
              expect(subject).to eq true
              expect(authorizer.veteran_poa?).to eq false
              expect(authorizer.claimant_poa?).to eq true
              expect(authorizer.poa_denied).to eq true
              expect(authorizer.veteran_deceased?).to eq true
              expect(authorizer.sensitive_file).to be_falsey
            end
          end
        end
      end
    end
  end

  describe "veteran_poa?" do
  end
end
