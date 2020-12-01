describe Record do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end
  let(:manifest) { Manifest.create(file_number: "1234") }
  let(:source) { ManifestSource.create(name: %w[VBMS VVA].sample, manifest: manifest) }

  context ".create_from_external_document" do
    subject { Record.create_from_external_document(source, external_document) }

    let(:external_document) do
      OpenStruct.new(
        document_id: "12345",
        series_id: "6789",
        version: "2",
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
      expect(subject.version_id).to eq "12345"
      expect(subject.series_id).to eq "6789"
      expect(subject.version).to eq 2
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
      Record.new(version_id: "{TEST}", mime_type: "application/pdf")
    end

    it { is_expected.to eq("{TEST}.pdf") }
  end

  context "#filename" do
    subject { document.filename }

    context "all the components are present" do
      let(:document) do
        Record.new(
          received_at: Time.utc(2015, 1, 3, 17, 0, 0),
          type_id: "89",
          version_id: "{ABC123-DEF123-GHI456}",
          mime_type: "application/pdf"
        )
      end

      it { is_expected.to eq("STR-20150103-ABC123-DEF123-GHI456.pdf") }
    end

    context "when filename length equals 100" do
      let(:document) do
        Record.new(
          received_at: Time.utc(2015, 1, 3, 17, 0, 0),
          type_id: "497",
          version_id: "{ABC123-DEF123-GHI456A}",
          mime_type: "application/pdf"
        )
      end

      it { is_expected.to eq("VA 27-0820b Report of Nursing Home or Assisted Living Information-20150103-ABC123-DEF123-GHI456A.pdf") }
    end

    context "when filename length is greater than 100 (101)" do
      let(:document) do
        Record.new(
          received_at: Time.utc(2015, 1, 3, 17, 0, 0),
          type_id: "497",
          version_id: "{ABC123-DEF123-GHI456AB}",
          mime_type: "application/pdf"
        )
      end

      it { is_expected.to eq("VA 27-0820b Report of Nursing Home or Assisted Living Informatio-20150103-ABC123-DEF123-GHI456AB.pdf") }
    end
  end

  context ".create" do
    let(:mime_type) { "application/octet-stream" }
    let(:record) { Record.create(mime_type: mime_type, version_id: "1234", series_id: "5678", manifest_source: source) }

    context "mime_type" do
      subject { record.mime_type }

      context "if application/octet-stream" do
        it { is_expected.to eq("application/pdf") }
      end
    end

    context "temp_id" do
      subject { record.temp_id }

      it { is_expected.to eq(record.id) }
    end
  end

  context "#preferred_extension" do
    let(:record) do
      Record.new(version_id: "{TEST}", mime_type: mime_type)
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
      it "returns tiff" do
        expect(record.preferred_extension).to eq("tiff")
      end

      context "and conversion_status is :conversion_success" do
        let(:record) do
          Record.new(version_id: "{TEST}", mime_type: mime_type, conversion_status: :conversion_success)
        end

        it "returns pdf" do
          expect(record.preferred_extension).to eq("pdf")
        end
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
    let(:record) { Record.new(manifest_source: source) }

    subject { record.accessible_by?(user) }

    context "when user downloaded the manifest" do
      let!(:files_download) { FilesDownload.create(manifest: manifest, user: user) }
      it { is_expected.to eq(true) }
    end

    context "when user did not download the manifest" do
      it { is_expected.to eq(false) }
    end
  end
end
