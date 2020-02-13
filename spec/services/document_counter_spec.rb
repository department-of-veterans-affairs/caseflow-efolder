describe DocumentCounter do
  let(:vva_documents) do
    [
      OpenStruct.new(document_id: "11", series_id: "3"),
      OpenStruct.new(document_id: "11", series_id: "4"), # dupe document_id
      OpenStruct.new(document_id: "12", series_id: "4", type_id: DocumentFilter::RESTRICTED_TYPES.sample)
    ]
  end

  before do
    allow(Fakes::VVAService).to receive(:v2_fetch_documents_for).and_return(vva_documents)
    allow_any_instance_of(VeteranFinder).to receive(:find) { [ { file: "DEMOFAST" } ] }
  end

  describe "#count" do
    subject { described_class.new(veteran_file_number: "DEMOFAST") }

    it "returns total unrestricted document count for all sources" do
      expect(subject.count).to eq(11) # 10 for DEMOFAST + 1 unrestricted vva_documents (skips duplicate document_id)
    end
  end
end
