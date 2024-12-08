# frozen_string_literal: true

describe ExternalApi::VBMSService do
  subject(:described) { described_class }

  let(:mock_error_handler) { instance_double(ErrorHandlers::ClaimEvidenceApiErrorHandler) }
  let(:mock_json_adapter) { instance_double(JsonApiResponseAdapter) }
  let(:mock_sensitivity_checker) { instance_double(SensitivityChecker, sensitivity_levels_compatible?: true) }

  before do
    allow(ErrorHandlers::ClaimEvidenceApiErrorHandler).to receive(:new).and_return(mock_error_handler)
    allow(JsonApiResponseAdapter).to receive(:new).and_return(mock_json_adapter)
    allow(SensitivityChecker).to receive(:new).and_return(mock_sensitivity_checker)
  end

  describe ".verify_user_veteran_access" do
    let!(:user) do
      user = User.create(css_id: "VSO", station_id: "283", participant_id: "1234")
      RequestStore.store[:current_user] = user
    end

    it "checks the user's sensitivity" do
      expect(mock_sensitivity_checker).to receive(:sensitivity_levels_compatible?)
        .with(user: user, veteran_file_number: "123456789").and_return(true)

      described.verify_user_veteran_access("123456789")
    end

    it "raises an exception when the sensitivity level is not compatible" do
      expect(mock_sensitivity_checker).to receive(:sensitivity_levels_compatible?)
        .with(user: user, veteran_file_number: "123456789").and_return(false)

      expect { described.verify_user_veteran_access("123456789") }
        .to raise_error(RuntimeError, "User does not have permission to access this information")
    end
  end

  describe ".v2_fetch_documents_for" do
    before do
      FeatureToggle.enable!(:use_ce_api)
    end

    after { FeatureToggle.disable!(:use_ce_api) }

    context "with use_ce_api feature toggle enabled" do
      before { FeatureToggle.enable!(:use_ce_api) }
      after { FeatureToggle.disable!(:use_ce_api) }

      it "calls the CE API" do
        veteran_id = "123456789"

        expect(VeteranFileFetcher).to receive(:fetch_veteran_file_list)
          .with(veteran_file_number: veteran_id, claim_evidence_request: instance_of(ClaimEvidenceRequest))
        expect(mock_json_adapter).to receive(:adapt_v2_fetch_documents_for).and_return([])

        described.v2_fetch_documents_for(veteran_id)
      end
    end

    context "with vbms_pagination feature toggle enabled" do
      let!(:user) do
        user = User.create(css_id: "VSO", station_id: "283", participant_id: "1234")
        RequestStore.store[:current_user] = user
      end

      it "calls the PagedDocuments SOAP API endpoint" do
        veteran_id = "123456789"

        expect(FeatureToggle).to receive(:enabled?).with(:use_ce_api, user: user).and_return(false)
        expect(FeatureToggle).to receive(:enabled?).with(:vbms_pagination, user: user).and_return(true)
        expect(described_class).to receive(:vbms_client)
        expect(VBMS::Service::PagedDocuments).to receive(:new).and_return(:test_service)
        expect(described_class).to receive(:call_and_log_service)
          .with(service: :test_service, vbms_id: veteran_id).and_return(documents: [])

        described.v2_fetch_documents_for(veteran_id)
      end
    end

    context "with no feature toggles enabled" do
      let!(:user) do
        user = User.create(css_id: "VSO", station_id: "283", participant_id: "1234")
        RequestStore.store[:current_user] = user
      end

      it "calls the FindDocumentVersionReference SOAP API endpoint" do
        veteran_id = "123456789"
        expect(FeatureToggle).to receive(:enabled?).with(:use_ce_api, user: user).and_return(false)
        expect(FeatureToggle).to receive(:enabled?).with(:vbms_pagination, user: user).and_return(false)
        expect(VBMS::Requests::FindDocumentVersionReference).to receive(:new)
          .with(veteran_id).and_return(:test_service)
        expect(described_class).to receive(:send_and_log_request)
          .with(veteran_id, :test_service).and_return(documents: [])

        described.v2_fetch_documents_for(veteran_id)
      end
    end
  end

  describe ".fetch_delta_documents_for" do
    before do
      FeatureToggle.enable!(:use_ce_api)
    end

    after { FeatureToggle.disable!(:use_ce_api) }

    context "with use_ce_api feature toggle enabled" do
      before { FeatureToggle.enable!(:use_ce_api) }
      after { FeatureToggle.disable!(:use_ce_api) }

      it "calls the CE API" do
        veteran_file_number = "123456789"
        begin_date_range = "2024-05-10"
        end_date_range = "2024-05-10"
        expect(VeteranFileFetcher).to receive(:fetch_veteran_file_list_by_date_range)
          .with(
            veteran_file_number: veteran_file_number,
            claim_evidence_request: instance_of(ClaimEvidenceRequest),
            begin_date_range: begin_date_range,
            end_date_range: end_date_range
          )
        expect(mock_json_adapter).to receive(:adapt_v2_fetch_documents_for).and_return([])
        described.fetch_delta_documents_for(veteran_file_number, begin_date_range, end_date_range)
      end
    end
  end

  describe ".v2_fetch_document_file" do
    context "with use_ce_api feature toggle enabled" do
      before do
        FeatureToggle.enable!(:use_ce_api)
      end

      after do
        FeatureToggle.disable!(:use_ce_api)
      end

      let(:manifest) { Manifest.create(file_number: "1234") }
      let(:source) { ManifestSource.create(name: %w[VBMS VVA].sample, manifest: manifest) }

      let(:fake_record) do
        Record.create(
          version_id: "{3333-3333}",
          series_id: "{4444-4444}",
          received_at: Time.utc(2015, 9, 6, 1, 0, 0),
          type_id: "825",
          mime_type: "application/pdf",
          manifest_source: source
        )
      end

      it "calls the CE API" do
        expect(VeteranFileFetcher)
          .to receive(:get_document_content)
          .with(doc_series_id: fake_record.series_id, claim_evidence_request: instance_of(ClaimEvidenceRequest))
          .and_return("Pdf Byte String")

        described.v2_fetch_document_file(fake_record)
      end
    end
  end

  describe ".process_fetch_veteran_file_list_response" do
    before do
      FeatureToggle.enable!(:use_ce_api)
    end

    after { FeatureToggle.disable!(:use_ce_api) }

    context "when the adapted response is present" do
      it "does not log any errors and returns the adapted response" do
        expect(mock_json_adapter).to receive(:adapt_v2_fetch_documents_for).and_return(["foo"])
        expect(ExceptionLogger).not_to receive(:capture)

        result = described.process_fetch_veteran_file_list_response(nil)
        expect(result.count).to eq 1
      end
    end

    context "when the adapted response is nil" do
      let!(:user) do
        user = User.create(css_id: "VSO", station_id: "283", participant_id: "1234")
        RequestStore.store[:current_user] = user
      end

      it "logs an exception and returns an empty array" do
        expect(mock_json_adapter).to receive(:adapt_v2_fetch_documents_for).and_return(nil)
        expect(RuntimeError).to receive(:new).with(/API response could not be parsed/).and_call_original
        expect(mock_sensitivity_checker).to receive(:sensitivity_level_for_user)
          .with(user).and_return(4)
        expect(SecureRandom).to receive(:uuid).and_return("1234")
        expect(mock_error_handler).to receive(:handle_error)
          .with(
            error: instance_of(RuntimeError),
            error_details: {
              user_css_id: user.css_id,
              user_sensitivity_level: 4,
              error_uuid: "1234"
            }
          )

        result = described.process_fetch_veteran_file_list_response(nil)
        expect(result).to eq []
      end
    end
  end

  describe ".claim_evidence_request" do
    context "with send_current_user_cred_to_ce_api feature toggle enabled" do
      before { FeatureToggle.enable!(:send_current_user_cred_to_ce_api) }

      context "when current_user is set in the RequestStore" do
        let!(:user) do
          user = User.create(css_id: "VSO", station_id: "283", participant_id: "1234")
          RequestStore[:current_user] = user
        end

        it "returns user credentials" do
          result = described.claim_evidence_request

          expect(result.user_css_id).to eq user.css_id
          expect(result.station_id).to eq user.station_id
        end
      end

      context "when current_user is NOT set in the RequestStore" do
        before do
          RequestStore[:current_user] = nil
          ENV["CLAIM_EVIDENCE_VBMS_USER"] = "CSS_123"
          ENV["CLAIM_EVIDENCE_STATION_ID"] = "123"
        end
        it "returns system credentials" do
          result = described.claim_evidence_request
          expect(result.user_css_id).to eq "CSS_123"
          expect(result.station_id).to eq "123"
        end
      end
    end

    context "with send_current_user_cred_to_ce_api feature toggle disabled" do
      before do
        FeatureToggle.disable!(:send_current_user_cred_to_ce_api)
        ENV["CLAIM_EVIDENCE_VBMS_USER"] = "CSS_999"
        ENV["CLAIM_EVIDENCE_STATION_ID"] = "999"
      end

      context "when current_user is set in the RequestStore" do
        let(:user) do
          user = create(:user)
          RequestStore[:current_user] = user
        end

        it "returns system credentials" do
          result = described.claim_evidence_request

          expect(result.user_css_id).to eq "CSS_999"
          expect(result.station_id).to eq "999"
        end
      end

      context "when current_user is NOT set in the RequestStore" do
        before { RequestStore[:current_user] = nil }
        it "returns system credentials" do
          result = described.claim_evidence_request
          expect(result.user_css_id).to eq "CSS_999"
          expect(result.station_id).to eq "999"
        end
      end
    end
  end

  describe "error handling" do
    let(:example_error) { StandardError.new("My test error") }
    let(:veteran_file_number) { "123456789" }

    before do
      FeatureToggle.enable!(:use_ce_api)
    end
    after { FeatureToggle.disable!(:use_ce_api) }

    context "when the current_user is set in the RequestStore" do
      let!(:user) do
        user = User.create(css_id: "VSO", station_id: "283", participant_id: "1234")
        RequestStore.store[:current_user] = user
      end

      it "reports errors to the ClaimEvidenceApiErrorHandler and includes the current_user details" do
        expect(mock_sensitivity_checker).to receive(:sensitivity_levels_compatible?)
          .with(user: user, veteran_file_number: veteran_file_number).and_return(true)
        expect(VeteranFileFetcher).to receive(:fetch_veteran_file_list)
          .with(
            veteran_file_number: veteran_file_number,
            claim_evidence_request: instance_of(ClaimEvidenceRequest)
          ).and_raise(example_error)
        expect(mock_sensitivity_checker).to receive(:sensitivity_level_for_user)
          .with(user).and_return(4)
        expect(SecureRandom).to receive(:uuid).and_return("1234")
        expect(mock_error_handler).to receive(:handle_error)
          .with(
            error: example_error,
            error_details: {
              user_css_id: user.css_id,
              user_sensitivity_level: 4,
              error_uuid: "1234"
            }
          )

        response = described.v2_fetch_documents_for(veteran_file_number)
        expect(response).to eq([])
      end
    end

    context "when the current_user is NOT set in the RequestStore" do
      before { RequestStore.store[:current_user] = nil }

      it "reports errors to the ClaimEvidenceApiErrorHandler" do
        expect(mock_sensitivity_checker).not_to receive(:sensitivity_levels_compatible?)
        expect(VeteranFileFetcher).to receive(:fetch_veteran_file_list)
          .with(
            veteran_file_number: veteran_file_number,
            claim_evidence_request: instance_of(ClaimEvidenceRequest)
          ).and_raise(example_error)
        expect(mock_sensitivity_checker).not_to receive(:sensitivity_level_for_user)
        expect(SecureRandom).to receive(:uuid).and_return("1234")
        expect(mock_error_handler).to receive(:handle_error)
          .with(
            error: example_error,
            error_details: {
              user_css_id: "User is not set in the RequestStore",
              user_sensitivity_level: "User is not set in the RequestStore",
              error_uuid: "1234"
            }
          )

        response = described.v2_fetch_documents_for(veteran_file_number)
        expect(response).to eq([])
      end
    end
  end
end
