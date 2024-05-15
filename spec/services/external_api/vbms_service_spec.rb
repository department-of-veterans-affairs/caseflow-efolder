# frozen_string_literal: true

describe ExternalApi::VBMSService do
  subject(:described) { described_class }

  describe ".v2_fetch_documents_for" do
    let(:mock_veteran_file_fetcher) { instance_double(ExternalApi::VeteranFileFetcher) }
    let(:mock_json_adapter) { instance_double(JsonApiResponseAdapter) }

    before do
      allow(ExternalApi::VeteranFileFetcher).to receive(:new).and_return(mock_veteran_file_fetcher)
      allow(JsonApiResponseAdapter).to receive(:new).and_return(mock_json_adapter)
    end

    context "with use_ce_api feature toggle enabled" do
      before { FeatureToggle.enable!(:use_ce_api) }
      after { FeatureToggle.disable!(:use_ce_api) }

      it "calls the CE API" do
        veteran_id = "123456789"

        expect(mock_veteran_file_fetcher).to receive(:fetch_veteran_file_list).with(veteran_file_number: veteran_id)
        expect(mock_json_adapter).to receive(:adapt_v2_fetch_documents_for).and_return([])

        described.v2_fetch_documents_for(veteran_id)
      end
    end
  end

  describe ".fetch_delta_documents_for" do
    let(:mock_veteran_file_fetcher) { instance_double(ExternalApi::VeteranFileFetcher) }
    let(:mock_json_adapter) { instance_double(JsonApiResponseAdapter) }

    before do
      allow(ExternalApi::VeteranFileFetcher).to receive(:new).and_return(mock_veteran_file_fetcher)
      allow(JsonApiResponseAdapter).to receive(:new).and_return(mock_json_adapter)
    end

    context "with use_ce_api feature toggle enabled" do
      before { FeatureToggle.enable!(:use_ce_api) }
      after { FeatureToggle.disable!(:use_ce_api) }

      it "calls the CE API" do
        veteran_file_number = "123456789"
        begin_date_range = "2024-05-10"
        end_date_range = "2024-05-10"

        expect(mock_veteran_file_fetcher).to receive(:fetch_veteran_file_list_by_date_range)
        .with(
          veteran_file_number: veteran_file_number,
          begin_date_range: begin_date_range,
          end_date_range: end_date_range
        )
        expect(mock_json_adapter).to receive(:adapt_v2_fetch_documents_for).and_return([])
        described.fetch_delta_documents_for(veteran_file_number, begin_date_range, end_date_range)
      end
    end
  end
end