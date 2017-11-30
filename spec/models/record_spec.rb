describe Record do
  context ".create_from_external_document" do
    before do
      Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
    end

    subject { Record.create_from_external_document(source, external_document) }

    let(:manifest) { Manifest.create(file_number: "1234") }
    let(:source) { ManifestSource.create(source: %w(VBMS VVA).sample, manifest: manifest) }
    let(:external_document) do
      OpenStruct.new(
        document_id: "12345",
        type_id: "777",
        type_description: "VA 8 Certification of Appeal",
        mime_type: "application/pdf",
        received_at: 2.days.ago,
        jro: "786",
        source: "VACOLS")
    end

    it "creates a record" do
      expect(subject.manifest_source).to eq source
      expect(subject.external_document_id).to eq "12345"
      expect(subject.type_id).to eq "777"
      expect(subject.type_description).to eq "VA 8 Certification of Appeal"
      expect(subject.received_at).to eq 2.days.ago
      expect(subject.jro).to eq "786"
      expect(subject.source).to eq "VACOLS"
    end
  end
end
