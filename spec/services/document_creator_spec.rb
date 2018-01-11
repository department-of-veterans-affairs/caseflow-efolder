describe DocumentCreator do
  let(:manifest) { Manifest.create(file_number: "1234") }
  let(:source) { ManifestSource.create(source: %w[VVA VBMS].sample, manifest: manifest) }

  context "#create" do
    subject { DocumentCreator.new(manifest_source: source, external_documents: documents).create }

    context "when there are external documents" do
      let(:documents) do
        [
          OpenStruct.new(document_id: "1"),
          OpenStruct.new(document_id: "2")
        ]
      end
      it "creates the documents" do
        expect(source.records).to eq []
        subject
        expect(source.reload.records.size).to eq 2
      end
    end

    context "when there are no external documents" do
      let(:documents) { [] }

      it "does not create any documents" do
        expect(source.records).to eq []
        subject
        expect(source.reload.records.size).to eq 0
      end
    end

    context "when there are restricted document types" do
      let(:documents) do
        [
          OpenStruct.new(document_id: "1", type_id: DocumentCreator::RESTRICTED_TYPES.sample),
          OpenStruct.new(document_id: "2", type_id: "554")
        ]
      end

      it "skips the restricted documents" do
        expect(source.records).to eq []
        subject
        expect(source.reload.records.size).to eq 1
        expect(source.reload.records.first.external_document_id).to eq "2"
      end
    end
  end
end
