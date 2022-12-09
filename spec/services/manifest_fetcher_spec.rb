describe ManifestFetcher do
  let(:manifest) { Manifest.create(file_number: "1234") }
  let(:source) { ManifestSource.create(name: name, manifest: manifest) }

  let(:documents) do
    [
      OpenStruct.new(document_id: "1", series_id: "3"),
      OpenStruct.new(document_id: "2", series_id: "4")
    ]
  end
  let(:delta_documents) do
    [
      OpenStruct.new(document_id: "5", series_id: "1"),
      OpenStruct.new(document_id: "6", series_id: "2")
    ]
  end

  before do
    allow_any_instance_of(VeteranFinder).to receive(:find) { [ { file: "1234" } ] }
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
          expect(source.reload.records.size).to eq 2
          expect(source.reload.status).to eq "success"
          expect(source.reload.fetched_at).to_not be_nil
        end
      end
      
      context "when manifest source is current returns manifest with delta docs" do
        before do
          FeatureToggle.enable!(:cache_delta_documents)
          source.records.create(version_id: "3", series_id: "1")
          source.records.create(version_id: "4", series_id: "2")
          source.records.create(version_id: "7", series_id: "3")
          source.fetched_at = Time.zone.now
          source.status = "success"
          allow(VBMSService).to receive(:fetch_delta_documents_for).and_return(delta_documents)
        end
        after { FeatureToggle.disable!(:cache_delta_documents) }
        
        it "saves manifest status as success, updated fetched at, replaced old documents with new versions" do
          expect(subject.size).to eq 2
          expect(source.reload.records.size).to eq 3
          expect(source.reload.records.find_by(series_id: "3").version_id).to eq "7"
          expect(source.reload.records.find_by(series_id: "2").version_id).to eq "6"
          expect(source.reload.records.find_by(series_id: "1").version_id).to eq "5"
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
  
  context "#documents" do
    before {FeatureToggle.enable!(:cache_delta_documents)}
    after { FeatureToggle.disable!(:cache_delta_documents) }
    subject { ManifestFetcher.new(manifest_source: source).documents }
      context "from VBMS" do
        let(:name) { "VBMS" }

        context "when manifest source is current" do
          before do
            source.fetched_at = Time.zone.now
            source.status = "success"
            allow(VBMSService).to receive(:fetch_delta_documents_for).and_return(delta_documents)
          end

          it "returns the delta documents" do
            expect(subject.size).to eq 2
            expect(subject.first.document_id).to eq "5"
          end
        end
        context "when manifest source is not current" do
          before do
            allow(VBMSService).to receive(:v2_fetch_documents_for).and_return(documents)
          end
          
          it "returns all documents" do
            expect(subject.size).to eq 2
            expect(subject.first.document_id).to eq "1"
          end
        end
      end
  end
end
