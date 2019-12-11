describe ZipfileCreator do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
    Dir.mkdir(dir_path) unless File.exist?(dir_path)
    allow(S3Service).to receive(:fetch_content).and_return(nil)
  end

  after do
    FileUtils.rm_rf(dir_path)
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
            mime_type: "application/pdf"
          )
        ]
      end

      it "should create a zip file with all files" do
        subject
        expect(manifest.zipfile_size).to_not eq nil
        expect(manifest.number_successful_documents).to eq 3
        expect(manifest.number_failed_documents).to eq 0
        S3Service.fetch_file(manifest.s3_filename, zip_path)
        Zip::File.open(zip_path) do |zip_file|
          expect(zip_file.size).to eq 3
          expect(zip_file.glob("00010-test1-20170103-FDC123-DEF123-GHI456A.pdf").first).to_not be_nil
        end
      end
    end

    context "when manifest has so many files that combined add up to 4G+ .zip", large_files: true do
      let(:number_of_files) { 65 }
      let!(:records) do
        number_of_files.times do |n|
          manifest.vbms_source.records.create(
            received_at: Time.utc(2015, 1, 3, 17, 0, 0),
            type_description: "test#{n}",
            version_id: "{ABC123-DEF123-GHI456A-#{n}}",
            series_id: "{ABC321-DEF123-GHI456A-#{n}}",
            mime_type: "application/pdf"
          )
        end
      end

      before do
        # ensure at least one of our .pdf files is 500+ MB so we can triger the large .zip file.
        pdf_dir = Rails.root + "lib/pdfs"
        # we arbitrarily overrite 2.pdf with a large amount of random data
        large_file = "#{pdf_dir}/2.pdf"
        if File.size(large_file) < 500_000_000
          puts "The expected large file #{large_file} is not large. Overwriting it with random data."
          puts "You will *not* want to commit this file in any Git changes, so revert it before commit:"
          puts "  git checkout #{large_file}"
          puts "after this test finishes."
          system("openssl rand -out #{large_file} -base64 $(( 2**29 * 3/4 ))")
        end

        # avoid reading/writing huge file multiple times into memory.
        allow(S3Service).to receive(:store_file) do |filename, content, type|
          type ||= :content
          S3Service.files ||= {}
          tmpfile = "#{dir_path}#{filename}"
          if type == :content
            File.open(tmpfile, "wb") { |f| f.write(content) }
          elsif type == :filepath
            FileUtils.cp content, tmpfile
          else
            raise "Unknown type #{type}"
          end
          S3Service.files[filename] = tmpfile
        end
        # rubocop:disable Style/IfUnlessModifier
        allow(S3Service).to receive(:fetch_file) do |filename, dest_filepath|
          S3Service.files ||= {}
          unless FileUtils.identical?(S3Service.files[filename], dest_filepath) # may already exist
            FileUtils.cp S3Service.files[filename], dest_filepath
          end
        end
        # rubocop:enable Style/IfUnlessModifier
      end

      it "should create a valid zip64 file" do
        subject
        expect(manifest.zipfile_size).to be > 4_100_000_000
        expect(manifest.number_successful_documents).to eq number_of_files
        S3Service.fetch_file(manifest.s3_filename, zip_path)
        Zip::File.open(zip_path) do |zip_file|
          expect(zip_file.size).to eq number_of_files
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
            mime_type: "application/pdf"
          )
        ]
      end

      it "should create a zip file with VBMS documents only" do
        subject
        expect(manifest.number_successful_documents).to eq 2
        expect(manifest.number_failed_documents).to eq 1
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
            mime_type: "application/pdf"
          )
        ]
      end

      it "should create a zip file with VVA documents only" do
        subject
        expect(manifest.number_successful_documents).to eq 1
        expect(manifest.number_failed_documents).to eq 2
        S3Service.fetch_file(manifest.s3_filename, zip_path)
        Zip::File.open(zip_path) do |zip_file|
          expect(zip_file.size).to eq 1
          expect(zip_file.glob("00010-test1-20170103-FDC123-DEF123-GHI456A.pdf").first).to_not be_nil
        end
      end
    end
  end
end
