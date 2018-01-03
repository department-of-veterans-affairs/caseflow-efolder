describe ImageConverterService do
  let(:tiff_file) { Rails.root + "lib/tiffs/0.tiff" }
  let(:tiff_content) { File.open(tiff_file, "r", &:read) }

  let(:pdf_file) { Rails.root + "lib/pdfs/0.pdf" }
  let(:pdf_content) { File.open(tiff_file, "r", &:read) }

  let(:mime_type) { "image/tiff" }
  let(:image_converter) { ImageConverterService.new(image: tiff_content, mime_type: mime_type) }

  before { FeatureToggle.enable!(:convert_tiff_images) }
  after { FeatureToggle.disable!(:convert_tiff_images) }

  context "#process" do
    context "when image is a tiff" do
      it "calls service" do
        allow_any_instance_of(ImageConverterService).to receive(:convert_tiff_to_pdf).and_return(pdf_content)
        expect(image_converter.process).to eq(pdf_content)
      end
    end

    context "when image is a pdf" do
      let(:mime_type) { "application/pdf" }
      let(:image_converter) { ImageConverterService.new(image: pdf_content, mime_type: mime_type) }

      it "doesn't change it" do
        expect(image_converter.process).to eq(pdf_content)
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
