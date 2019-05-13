describe DocumentCounter do
  let(:manifest) { Manifest.create(file_number: "1234") }
  let(:vva_source) { ManifestSource.create(name: "VVA", manifest: manifest) }
  let(:vbms_source) { ManifestSource.create(name: "VBMS", manifest: manifest) }
  let(:vbms_documents) do
    [
      OpenStruct.new(document_id: "1", series_id: "3"),
      OpenStruct.new(document_id: "2", series_id: "4", type_id: DocumentFilter::RESTRICTED_TYPES.sample)
    ]
  end
  let(:vva_documents) do
    [
      OpenStruct.new(document_id: "11", series_id: "3"),
      OpenStruct.new(document_id: "12", series_id: "4", type_id: DocumentFilter::RESTRICTED_TYPES.sample)
    ]
  end
  let(:vva_fetcher) { ManifestFetcher.new(manifest_source: vva_source) }
  let(:vbms_fetcher) { ManifestFetcher.new(manifest_source: vbms_source) }

  before do
    allow(vva_fetcher).to receive(:fetch_documents).and_return(vva_documents)
    allow(vbms_fetcher).to receive(:fetch_documents).and_return(vbms_documents)
    allow(ManifestFetcher).to receive(:new).with(manifest_source: vva_source).and_return(vva_fetcher)
    allow(ManifestFetcher).to receive(:new).with(manifest_source: vbms_source).and_return(vbms_fetcher)
  end

  describe "#count" do
    subject { described_class.new(manifest: manifest) }

    it "returns total unrestricted document count for all sources" do
      expect(subject.count).to eq(2)
    end
  end
end
