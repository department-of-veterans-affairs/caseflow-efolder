# frozen_string_literal: true

describe Record do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end
  let(:manifest) { Manifest.create(file_number: "1234") }
  let(:source) { ManifestSource.create(source: %w[VBMS VVA].sample, manifest: manifest) }

  context ".create_from_external_document" do
    subject { Record.create_from_external_document(source, external_document) }

    let(:external_document) do
      OpenStruct.new(
        document_id: "12345",
        type_id: "777",
        type_description: "VA 8 Certification of Appeal",
        mime_type: "application/pdf",
        received_at: 2.days.ago,
        jro: "786",
        source: "VACOLS"
      )
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

  context "#s3_filename" do
    subject { record.s3_filename }

    let(:record) do
      Record.new(external_document_id: "{TEST}", mime_type: "application/pdf")
    end

    it { is_expected.to eq("{TEST}.pdf") }
  end

  context ".create" do
    context "mime_type" do
      subject do
        Record.create(
          mime_type: mime_type,
          external_document_id: "1234",
          manifest_source: source
        ).mime_type
      end

      context "if application/octet-stream" do
        let(:mime_type) { "application/octet-stream" }

        it { is_expected.to eq("application/pdf") }
      end
    end
  end

  context "#preferred_extension" do
    let(:record) do
      Record.new(external_document_id: "{TEST}", mime_type: mime_type)
    end

    context "when passed application/pdf" do
      let(:mime_type) { "application/pdf" }
      it "returns pdf" do
        expect(record.preferred_extension).to eq("pdf")
      end
    end

    context "when passed image/tiff" do
      before do
        FeatureToggle.enable!(:convert_tiff_images)
      end

      let(:mime_type) { "image/tiff" }
      it "returns pdf" do
        expect(record.preferred_extension).to eq("pdf")
      end
    end

    context "when passed image/jpeg" do
      let(:mime_type) { "image/jpeg" }
      it "returns jpeg" do
        expect(record.preferred_extension).to eq("jpeg")
      end
    end
  end

  context "#accessible_by?" do
    let(:user) { User.create(css_id: "123", station_id: "456") }
    let(:record) { Record.create(manifest_source: source) }

    subject { record.accessible_by?(user) }

    context "when user downloaded the manifest" do
      let!(:user_manifest) { UserManifest.create(manifest: manifest, user: user) }
      it { is_expected.to eq(true) }
    end

    context "when user did not download the manifest" do
      it { is_expected.to eq(false) }
    end
  end
end
