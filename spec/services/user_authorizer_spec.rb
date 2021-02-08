# frozen_string_literal: true

describe UserAuthorizer do
  let(:roles) { ["Download eFolder"] }
  let(:file_number) { "66660000" }
  let(:veteran_participant_id) { "1234" }
  let(:claimant_participant_id) { "5678" }
  let(:bva_participant_id) { "123" }
  let(:poa_participant_id) { "456" }
  let(:poa_org_participant_id) { "999" }
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
      person_org_ptcpnt_id: poa_org_participant_id,
      person_organization_name: "POA Attorney",
      relationship_name: "Power of Attorney For",
      veteran_ptcpnt_id: veteran_participant_id
    }
  end
  let(:bgs_claimants_poa_pid_response) do
    {
      person_org_name: "A Lawyer",
      person_org_ptcpnt_id: poa_org_participant_id,
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
  let(:bgs_poa_user_response) do
    {
      nm: "A Lawyer",
      org_type_nm: "POA Attorney",
      ptcpnt_id: poa_org_participant_id
    }
  end
  let(:veteran_date_of_death) { "" }
  let(:authorizer) { described_class.new(user: user, file_number: file_number) }

  before do
    allow(authorizer).to receive(:bgs) { bgs_service }
    allow(authorizer).to receive(:system_bgs) { system_bgs_service }

    allow(bgs_client).to receive(:client_username) { css_id }
    allow(bgs_client).to receive(:client_station_id) { station_id }
    allow(bgs_client).to receive(:veteran) { bgs_veteran_service }
    allow(bgs_client).to receive(:claimants) { bgs_claimants_service }
    allow(bgs_client).to receive(:common_security) { bgs_security_service }
    allow(bgs_client).to receive(:benefit_claims) { bgs_benefit_claims_service }
    allow(bgs_client).to receive(:org) { bgs_org_service }

    allow(bgs_org_service).to receive(:find_poas_by_ptcpnt_id)
      .with(poa_participant_id) { bgs_poa_user_response }
    allow(bgs_claimants_service).to receive(:find_poa_by_file_number)
      .with(file_number) { bgs_claimants_poa_fn_response }
    allow(bgs_claimants_service).to receive(:find_poa_by_participant_id)
      .with(claimant_participant_id) { bgs_claimants_poa_pid_response }
    allow(bgs_veteran_service).to receive(:find_by_file_number)
      .with(file_number) { bgs_veteran_response }
    allow(system_bgs_veteran_service).to receive(:find_by_file_number)
      .with(file_number) { bgs_veteran_response }
    allow(bgs_security_service).to receive(:get_security_profile)
      .with(username: css_id, station_id: station_id, application: "CASEFLOW") { bgs_css_user_profile_response }
    allow(bgs_benefit_claims_service).to receive(:find_claim_by_file_number)
      .with(file_number) { bgs_benefit_claims_response }

    allow(system_bgs_client).to receive(:client_username) { User.system_user.css_id }
    allow(system_bgs_client).to receive(:client_station_id) { User.system_user.station_id }
    allow(system_bgs_client).to receive(:veteran) { system_bgs_veteran_service }
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
          expect(authorizer.sensitive_file?).to eq true
        end
      end
    end

    context "POA user" do
      let(:user) { poa_user }

      context "veteran is alive" do
        context "has POA for veteran" do
          it "returns true" do
            expect(subject).to eq true
          end
        end

        context "not POA for veteran" do
          let(:user) do
            User.new(
              participant_id: 00000000,
              css_id: "NOTPOA",
              email: "notpoa@example.com",
              name: "NOT POA", 
              roles: roles,
              station_id: "213"
            )
          end

          # Tests the issue described here:
          #
          #   https://github.com/department-of-veterans-affairs/caseflow/issues/15829
          it "returns false twice after veteran fetch with system BGS" do
            expect(bgs_veteran_service).to(
              receive(:find_by_file_number)
                .with(file_number)
                .and_raise(
                  BGS::ShareError.new("Power of Attorney of Folder is none. Access to this record is denied.")
                )
                .twice
            )
            # Fake that calling BGS as the system user will return the veteran's data
            # and not a permission error.
            expect(system_bgs_veteran_service).to(
              receive(:find_by_file_number)
                .with(file_number)
                .and_return({
                  file_number: "123456789",
                  veteran_first_name: "First",
                  veteran_last_name: "Last",
                  veteran_last_four_ssn: "6789",
                  participant_id: "123456",
                  deceased: false,
                  return_message: "Message"
                })
                .once
            )
            # Fake that the veteran does not have a POA, so the active user (NOTPOA)
            # should not have permission to the veteran's data.
            expect(bgs_org_service).to(
              receive(:find_poas_by_ptcpnt_id)
                .with(user.participant_id)
                .and_return([])
                .twice
            )
            # Ensure that we are only getting the veteran info cache key twice. This
            # setup ensures that we aren't making unexpected calls to fetch veteran
            # info.
            expect(bgs_service).to(
              receive(:fetch_veteran_info_cache_key)
                .and_call_original
                .twice
            )

            expect(subject).to eq false

            # This check makes a query to BGS using the system user to see if the
            # veteran record actually exists. The system user has permissions to
            # all data in Caseflow, so this request to BGS will always return real
            # veteran data (never a permission error).
            expect(authorizer.veteran_record_found?).to eq true

            # Ensure that the previous call to BGS as the system user doesn't cache
            # data under the active user. This behavior would allow the active user to
            # bypass BGS permissions if they make a 2nd request before the cache expires.
            expect(Rails.cache.fetch("bgs_veteran_info_NOTPOA_213_#{file_number}")).to be_nil
            expect(Rails.cache.fetch("bgs_veteran_info_CASEFLOW1_317_#{file_number}")).not_to be_nil

            # Ensure that a second permission check returns the same exact result.
            # This is to ensure that the caching layer does bypass checks in BGS.
            authorizer2 = described_class.new(user: user, file_number: file_number)

            allow(authorizer2).to receive(:bgs) { bgs_service }
            allow(authorizer2).to receive(:system_bgs) { system_bgs_service }

            expect(authorizer2.can_read_efolder?).to eq false
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

          # what BGS returns if no POA is found
          let(:bgs_claimants_poa_fn_response) { nil }

          context "does not have POA for claimant" do
            let(:bgs_claimants_poa_pid_response) { nil }

            it "returns false" do
              expect(subject).to eq false
              expect(authorizer.veteran_record_poa_denied?).to eq true
              expect(authorizer.veteran_poa?).to eq false
              expect(authorizer.claimant_poa?).to eq false
              expect(authorizer.veteran_deceased?).to eq true
              expect(authorizer.sensitive_file?).to be_falsey
            end
          end

          context "has POA for claimant" do
            it "returns true" do
              expect(subject).to eq true
              expect(authorizer.veteran_poa?).to eq false
              expect(authorizer.claimant_poa?).to eq true
              expect(authorizer.veteran_record_poa_denied?).to eq true
              expect(authorizer.veteran_deceased?).to eq true
              expect(authorizer.sensitive_file?).to be_falsey
            end
          end
        end
      end
    end
  end
end
