describe ManifestFetcher do
  let(:manifest) { Manifest.create(file_number: "1234") }
  let(:source) { ManifestSource.create(name: name, manifest: manifest) }

  let(:documents) do
    [
      OpenStruct.new(document_id: "1", series_id: "3"),
      OpenStruct.new(document_id: "2", series_id: "4")
    ]
  end

  context "#process" do
    subject { ManifestFetcher.new(manifest_source: source).process }

    context "from VBMS" do
      let(:name) { "VBMS" }

      context "when VBMS client returns manifest" do
        before do
          allow(VBMSService).to receive(:v2_fetch_documents_for).and_return(documents)
        end

        it "saves manifest status as success and updated fetched at" do
          expect(subject.size).to eq 2
          expect(source.reload.status).to eq "success"
          expect(source.reload.fetched_at).to_not be_nil
        end
      end

      context "when VBMS client returns error" do
        before do
          allow(VBMSService).to receive(:v2_fetch_documents_for).and_raise(VBMS::ClientError)
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
          allow(VVAService).to receive(:v2_fetch_documents_for).and_return(documents)
        end

        it "saves manifest status as success and updated fetched at" do
          expect(subject.size).to eq 2
          expect(source.reload.status).to eq "success"
          expect(source.reload.fetched_at).to_not be_nil
        end
      end

      context "when VVA client returns manifest with {F291C1BC-FCDE-4C58-8544-B4FCE2E59008}" do
        let(:documents) do
          [
            OpenStruct.new(document_id: "{F291C1BC-FCDE-4C58-8544-B4FCE2E59008}", series_id: "3"),
            OpenStruct.new(document_id: "2", series_id: "4")
          ]
        end

        before do
          allow(VVAService).to receive(:v2_fetch_documents_for).and_return(documents)
        end

        it "saves manifest status as success and updated fetched at" do
          expect(subject.size).to eq 1
          expect(source.reload.status).to eq "success"
          expect(source.reload.fetched_at).to_not be_nil
          expect(subject[0].document_id).to eq "2"
        end
      end

      context "when VVA client returns error" do
        before do
          allow(VVAService).to receive(:v2_fetch_documents_for).and_raise(VVA::ClientError)
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
