describe DocumentCounter do
  let(:manifest) { Manifest.create(file_number: "DEMOFAST") }
  let!(:vva_source) { ManifestSource.create(name: "VVA", manifest: manifest) }
  let!(:vbms_source) { ManifestSource.create(name: "VBMS", manifest: manifest) }
  let(:veteran) { Veteran.new(file_number: "DEMOFAST") }
  let(:vva_documents) do
    [
      OpenStruct.new(document_id: "11", series_id: "3"),
      OpenStruct.new(document_id: "12", series_id: "4", type_id: DocumentFilter::RESTRICTED_TYPES.sample)
    ]
  end

  before do
    allow(Fakes::VVAService).to receive(:v2_fetch_documents_for).and_return(vva_documents)
  end

  describe "#count" do
    context "with manifest" do
      subject { described_class.new(manifest: manifest) }

      it "returns total unrestricted document count for all sources" do
        expect(subject.count).to eq(11)
      end
    end

    context "with veteran" do
      subject { described_class.new(veteran: veteran) }

      it "returns total unrestricted document count for all sources" do
        expect(subject.count).to eq(11)
      end
    end
  end
end
