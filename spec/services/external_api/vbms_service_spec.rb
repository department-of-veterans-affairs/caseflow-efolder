# frozen_string_literal: true

describe ExternalApi::VBMSService do
  subject(:described) { described_class }
  let(:mock_veteran_file_fetcher) { instance_double(ExternalApi::VeteranFileFetcher) }
  let(:mock_json_adapter) { instance_double(JsonApiResponseAdapter) }

  before do
    allow(ExternalApi::VeteranFileFetcher).to receive(:new).and_return(mock_veteran_file_fetcher)
    allow(JsonApiResponseAdapter).to receive(:new).and_return(mock_json_adapter)
  end

  describe ".v2_fetch_documents_for" do
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

  describe ".v2_fetch_document_file" do
    context "with use_ce_api feature toggle enabled" do
      before { FeatureToggle.enable!(:use_ce_api) }
      after { FeatureToggle.disable!(:use_ce_api) }

      it "calls the CE API" do
        document_series_id = "123ABC789iUwU"

        expect(mock_veteran_file_fetcher)
          .to receive(:get_document_content)
          .with(veteran_file_number: document_series_id)
          .and_return(String)

        result = described.v2_fetch_document_file(document_series_id)
        expect(result.encoding).to eq(Encoding::ASCII_8BIT)
      end
    end
  end
end
