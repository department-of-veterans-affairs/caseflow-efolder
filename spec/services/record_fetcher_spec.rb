describe RecordFetcher do
  let(:manifest) { Manifest.create(file_number: "1234") }
  let(:source) { ManifestSource.create(source: %w[VBMS VVA].sample, manifest: manifest) }

  let(:record) do
    Record.create(
      external_document_id: "{3333-3333}",
      manifest_source: source,
      received_at: Time.utc(2015, 9, 6, 1, 0, 0),
      type_id: "825",
      mime_type: mime_type
    )
  end

  let(:mime_type) { "application/pdf" }
  let(:tiff_file) { Rails.root + "lib/tiffs/0.tiff" }
  let(:tiff_content) { File.open(tiff_file, "r", &:read) }
  let(:fake_pdf_content) { "From VBMS" }

  context "#process" do
    subject { RecordFetcher.new(record: record).process }

    context "when file is in S3" do
      before do
        allow(S3Service).to receive(:fetch_content).with(record.s3_filename).and_return("hello there")
      end

      it "should return the content from S3 and should not update the DB" do
        expect(subject).to eq "hello there"
      end
    end

    context "when VBMS/VVA returns an error" do
      before do
        allow(S3Service).to receive(:fetch_content).and_return(nil)
        allow(Fakes::DocumentService).to receive(:fetch_document_file).and_raise([VBMS::ClientError, VVA::ClientError].sample)
      end

      it "should return nil and update status" do
        expect(subject).to eq nil
        expect(record.reload.status).to eq "failed"
      end
    end

    context "when file is not in S3" do
      before do
        allow(S3Service).to receive(:fetch_content).and_return(nil)
        allow(Fakes::DocumentService).to receive(:fetch_document_file).and_return(fake_pdf_content)
      end

      it "should return the content from VBMS" do
        expect(subject).to eq fake_pdf_content
      end

      it "should update document DB fields" do
        subject
        expect(record.reload.status).to eq "success"
      end

      context "when VBMS returns a tiff file" do
        let(:mime_type) { "image/tiff" }

        before do
          FeatureToggle.enable!(:convert_tiff_images)
          allow(Fakes::DocumentService).to receive(:fetch_document_file).and_return(tiff_content)
          allow_any_instance_of(ImageConverterService).to receive(:convert_tiff_to_pdf).and_return(fake_pdf_content)
        end
        after { FeatureToggle.disable!(:convert_tiff_images) }

        it "should convert the tiff to pdf and return it" do
          expect(subject).to eq fake_pdf_content
        end
      end
    end
  end
end
