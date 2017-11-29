describe ManifestFetcher do
  let(:manifest) { Manifest.create(file_number: "1234") }
  let(:source) { ManifestSource.create(source: name, manifest: manifest) }

  let(:documents) do
    [
      OpenStruct.new(document_id: "1"),
      OpenStruct.new(document_id: "2")
    ]
  end

  context "#process" do
    subject { ManifestFetcher.new(manifest_source: source).process }

    context "from VBMS" do
      let(:name) { "VBMS" }

      context "when VBMS client returns manifest" do
        before do
          allow(VBMSService).to receive(:fetch_documents_for).and_return(documents)
        end

        it "saves manifest status as success and updated fetched at" do
          expect(subject.size).to eq 2
          expect(source.reload.status).to eq "success"
          expect(source.reload.fetched_at).to_not be_nil
        end
      end

      context "when VBMS client returns error" do
        before do
          allow(VBMSService).to receive(:fetch_documents_for).and_raise(VBMS::ClientError)
        end

        it "saves manifest status as failed" do
          expect(subject).to eq []
          expect(source.reload.status).to eq "failed"
          expect(source.reload.fetched_at).to be_nil
        end
      end
    end

    context "from VVA" do
      let(:name) { "VVA" }

      context "when VVA client returns manifest" do
        before do
          allow(VVAService).to receive(:fetch_documents_for).and_return(documents)
        end

        it "saves manifest status as success and updated fetched at" do
          expect(subject.size).to eq 2
          expect(source.reload.status).to eq "success"
          expect(source.reload.fetched_at).to_not be_nil
        end
      end

      context "when VBMS client returns error" do
        before do
          allow(VVAService).to receive(:fetch_documents_for).and_raise(VVA::ClientError)
        end

        it "saves manifest status as failed" do
          expect(subject).to eq []
          expect(source.reload.status).to eq "failed"
          expect(source.reload.fetched_at).to be_nil
        end
      end
    end
  end
end
