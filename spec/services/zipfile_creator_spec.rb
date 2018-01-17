describe ZipfileCreator do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
    Dir.mkdir(dir_path) unless File.exist?(dir_path)
    allow(S3Service).to receive(:fetch_content).and_return(nil)
  end

  let(:manifest) { Manifest.create(file_number: "1234") }
  let(:dir_path) { Rails.root + "tmp/files/" }
  let(:zip_path) { "#{dir_path}/#{manifest.s3_filename}" }

  context "#process" do
    subject { ZipfileCreator.new(manifest: manifest).process }

    context "when manifest has records and all services are up" do
      let!(:records) do
        [
          manifest.vbms_source.records.create(
            received_at: Time.utc(2015, 1, 3, 17, 0, 0),
            type_description: "test3",
            version_id: "{ABC123-DEF123-GHI456A}",
            series_id: "{ABC321-DEF123-GHI456A}",
            mime_type: "application/pdf"
          ),
          manifest.vva_source.records.create(
            received_at: Time.utc(2017, 1, 3, 17, 0, 0),
            type_description: "test1",
            version_id: "{FDC123-DEF123-GHI456A}",
            series_id: "{KYC321-DEF123-GHI456A}",
            mime_type: "application/pdf"
          ),
          manifest.vbms_source.records.create(
            received_at: Time.utc(2016, 1, 3, 17, 0, 0),
            type_description: "test2",
            version_id: "{CBA123-DEF123-GHI456A}",
            series_id: "{CBA321-DEF123-GHI456A}",
            mime_type: "application/pdf")
        ]
      end

      it "should create a zip file with all files" do
        subject
        expect(manifest.zipfile_size).to_not eq nil
        S3Service.fetch_file(manifest.s3_filename, zip_path)
        Zip::File.open(zip_path) do |zip_file|
          expect(zip_file.size).to eq 3
          expect(zip_file.glob("00010-test1-20170103-FDC123-DEF123-GHI456A.pdf").first).to_not be_nil
        end
      end
    end

    context "when manifest has records and VVA is down" do
      before do
        allow(VVAService).to receive(:v2_fetch_document_file).and_raise(VVA::ClientError)
      end
      let!(:records) do
        [
          manifest.vbms_source.records.create(
            received_at: Time.utc(2015, 1, 3, 17, 0, 0),
            type_description: "test3",
            version_id: "{ABC123-DEF123-GHI456A}",
            series_id: "{ABC321-DEF123-GHI456A}",
            mime_type: "application/pdf"
          ),
          manifest.vva_source.records.create(
            received_at: Time.utc(2017, 1, 3, 17, 0, 0),
            type_description: "test1",
            version_id: "{FDC123-DEF123-GHI456A}",
            series_id: "{KYC321-DEF123-GHI456A}",
            mime_type: "application/pdf"
          ),
          manifest.vbms_source.records.create(
            received_at: Time.utc(2016, 1, 3, 17, 0, 0),
            type_description: "test2",
            version_id: "{CBA123-DEF123-GHI456A}",
            series_id: "{CBA321-DEF123-GHI456A}",
            mime_type: "application/pdf")
        ]
      end

      it "should create a zip file with VBMS documents only" do
        subject
        S3Service.fetch_file(manifest.s3_filename, zip_path)
        Zip::File.open(zip_path) do |zip_file|
          expect(zip_file.size).to eq 2
          expect(zip_file.glob("00010-test2-20160103-CBA123-DEF123-GHI456A.pdf").first).to_not be_nil
        end
      end
    end

    context "when manifest has records and VBMS is down" do
      before do
        allow(VBMSService).to receive(:v2_fetch_document_file).and_raise(VBMS::ClientError)
      end
      let!(:records) do
        [
          manifest.vbms_source.records.create(
            received_at: Time.utc(2015, 1, 3, 17, 0, 0),
            type_description: "test3",
            version_id: "{ABC123-DEF123-GHI456A}",
            series_id: "{ABC321-DEF123-GHI456A}",
            mime_type: "application/pdf"
          ),
          manifest.vva_source.records.create(
            received_at: Time.utc(2017, 1, 3, 17, 0, 0),
            type_description: "test1",
            version_id: "{FDC123-DEF123-GHI456A}",
            series_id: "{KYC321-DEF123-GHI456A}",
            mime_type: "application/pdf"
          ),
          manifest.vbms_source.records.create(
            received_at: Time.utc(2016, 1, 3, 17, 0, 0),
            type_description: "test2",
            version_id: "{CBA123-DEF123-GHI456A}",
            series_id: "{CBA321-DEF123-GHI456A}",
            mime_type: "application/pdf")
        ]
      end

      it "should create a zip file with VVA documents only" do
        subject
        S3Service.fetch_file(manifest.s3_filename, zip_path)
        Zip::File.open(zip_path) do |zip_file|
          expect(zip_file.size).to eq 1
          expect(zip_file.glob("00010-test1-20170103-FDC123-DEF123-GHI456A.pdf").first).to_not be_nil
        end
      end
    end
  end
end