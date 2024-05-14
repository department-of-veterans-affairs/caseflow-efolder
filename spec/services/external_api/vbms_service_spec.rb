# frozen_string_literal: true

describe ExternalApi::VBMSService do
  subject(:described) { described_class }
  let(:mock_json_adapter) { instance_double(JsonApiResponseAdapter) }

  before do
    allow(JsonApiResponseAdapter).to receive(:new).and_return(mock_json_adapter)
  end

  describe ".v2_fetch_documents_for" do
    context "with use_ce_api feature toggle enabled" do
      before { FeatureToggle.enable!(:use_ce_api) }
      after { FeatureToggle.disable!(:use_ce_api) }

      it "calls the CE API" do
        veteran_id = "123456789"

        expect(VeteranFileFetcher).to receive(:fetch_veteran_file_list).with(veteran_file_number: veteran_id)
        expect(mock_json_adapter).to receive(:adapt_v2_fetch_documents_for).and_return([])

        described.v2_fetch_documents_for(veteran_id)
      end
    end
  end

  describe ".v2_fetch_document_file" do
    context "with use_ce_api feature toggle enabled" do
      before { FeatureToggle.enable!(:use_ce_api) }
      after { FeatureToggle.disable!(:use_ce_api) }

      let(:fake_record) do
        Record.create(
          version_id: "{3333-3333}",
          series_id: "{4444-4444}",
          received_at: Time.utc(2015, 9, 6, 1, 0, 0),
          type_id: "825",
          mime_type: "application/pdf"
        )
      end

      it "calls the CE API" do
        expect(VeteranFileFetcher)
          .to receive(:get_document_content)
          .with(doc_series_id: fake_record.series_id)
          .and_return("Pdf Byte String")

        described.v2_fetch_document_file(fake_record)
      end
    end
  end
end
