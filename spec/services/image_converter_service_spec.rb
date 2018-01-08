describe ImageConverterService, focus: true do
  let(:tiff_file) { Rails.root + "lib/tiffs/0.tiff" }
  let(:tiff_content) { File.open(tiff_file, "r", &:read) }

  let(:pdf_file) { Rails.root + "lib/pdfs/0.pdf" }
  let(:pdf_content) { File.open(tiff_file, "r", &:read) }

  let(:manifest) { Manifest.create(file_number: "1234") }
  let(:source) { ManifestSource.create(source: %w(VBMS VVA).sample, manifest: manifest) }
  let(:record) { Record.create(external_document_id: "TEST", manifest_source: source, mime_type: "image/tiff") }
  let(:image_converter) { ImageConverterService.new(image: tiff_content, record: record) }

  before { FeatureToggle.enable!(:convert_tiff_images) }
  after { FeatureToggle.disable!(:convert_tiff_images) }

  context "#process" do
    context "when image is a tiff" do
      it "returns pdf image and marks record as conversion_success" do
        allow_any_instance_of(ImageConverterService).to receive(:convert_tiff_to_pdf).and_return(pdf_content)
        expect(image_converter.process).to eq(pdf_content)
        expect(record.conversion_success?).to eq(true)
      end

      context "when service returns an error" do
        it "returns tiff image and marks record as conversion_failed" do
          allow(image_converter).to receive(:convert_tiff_to_pdf)
            .and_raise(ImageConverterService::ImageConverterError)
          expect(image_converter.process).to eq(tiff_content)
          expect(record.conversion_failed?).to eq(true)
        end
      end
    end

    context "when image is a pdf" do
      let(:record) { Record.create(external_document_id: "TEST", manifest_source: source, mime_type: "application/pdf") }
      let(:image_converter) { ImageConverterService.new(image: pdf_content, record: record) }

      it "doesn't change it and marks record as not_converted" do
        expect(image_converter.process).to eq(pdf_content)
        expect(record.not_converted?).to eq(true)
      end
    end
  end

  context ".converted_mime_type" do
    it "when type is image/tiff changes it to application/pdf" do
      expect(ImageConverterService.converted_mime_type("image/tiff")).to eq("application/pdf")
    end

    it "when type is image/jpeg doesn't change it" do
      expect(ImageConverterService.converted_mime_type("image/jpeg")).to eq("image/jpeg")
    end

    it "when type is applicaiton/pdf doesn't change it" do
      expect(ImageConverterService.converted_mime_type("application/pdf")).to eq("application/pdf")
    end
  end
end
