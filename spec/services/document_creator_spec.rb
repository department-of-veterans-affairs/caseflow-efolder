describe DocumentCreator do
  let(:manifest) { Manifest.create(file_number: "1234") }
  let(:source) { ManifestSource.create(name: %w[VVA VBMS].sample, manifest: manifest) }

  context "#create" do
    subject { DocumentCreator.new(manifest_source: source, external_documents: documents).create }

    context "when there are external documents" do
      let(:documents) do
        [
          OpenStruct.new(document_id: "1", series_id: "3"),
          OpenStruct.new(document_id: "2", series_id: "4")
        ]
      end
      it "creates the documents" do
        expect(source.records).to eq []
        subject
        expect(source.reload.records.size).to eq 2
      end
    end

    context "when external documents are nil" do
      let(:documents) { nil }

      it "does not create any documents" do
        expect(source.records).to eq []
        subject
        expect(source.reload.records.size).to eq 0
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
          OpenStruct.new(document_id: "1", series_id: "3", type_id: DocumentFilter::RESTRICTED_TYPES.sample),
          OpenStruct.new(document_id: "2", series_id: "4", type_id: "554")
        ]
      end

      it "skips the restricted documents" do
        expect(source.records).to eq []
        subject
        expect(source.reload.records.size).to eq 1
        expect(source.reload.records.first.version_id).to eq "2"
        expect(source.reload.records.first.series_id).to eq "4"
      end
    end

    context "when there is a restricted flag" do
      let(:documents) do
        [
          OpenStruct.new(document_id: "1", series_id: "3", type_id: "554"),
          OpenStruct.new(document_id: "2", series_id: "4", type_id: "554", restricted: true)
        ]
      end

      it "skips the restricted documents" do
        expect(source.records).to eq []
        subject
        expect(source.reload.records.size).to eq 1
        expect(source.reload.records.first.version_id).to eq "1"
        expect(source.reload.records.first.series_id).to eq "3"
      end
    end

    context "when documents contains duplicates" do
      let(:documents) do
        [
          OpenStruct.new(document_id: "1", series_id: "3"),
          OpenStruct.new(document_id: "2", series_id: "4"),
          OpenStruct.new(document_id: "2", series_id: "4")
        ]
      end

      it "only saves duplicate once" do
        subject
        expect(source.reload.records.size).to eq 2
        expect(source.reload.records.first.version_id).to eq "1"
        expect(source.reload.records.second.version_id).to eq "2"
      end
    end

    context "documents have been deleted from VBMS but still present in the DB" do
      let(:documents) do
        [
          OpenStruct.new(document_id: "1", series_id: "4"),
          OpenStruct.new(document_id: "2", series_id: "4")
        ]
      end

      it "removes deleted documents from the DB" do
        source.records.create(version_id: "3", series_id: "5")
        source.records.create(version_id: "4", series_id: "4")
        subject
        expect(source.reload.records.size).to eq 2
        expect(source.reload.records.first.series_id).to eq "4"
        expect(source.reload.records.second.series_id).to eq "4"
      end
    end
  end
end
