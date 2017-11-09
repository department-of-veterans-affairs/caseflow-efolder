describe Fetcher do
  let(:download) { Download.create(file_number: "21012") }
  let(:document) do
    download.documents.build(
      id: "1234",
      document_id: "{3333-3333}",
      received_at: Time.utc(2015, 9, 6, 1, 0, 0),
      type_id: "825",
      mime_type: "application/pdf"
    )
  end
  let(:tiff_file) { Rails.root + "lib/tiffs/0.tiff" }
  let(:pdf_file) { Rails.root + "lib/pdfs/0.pdf" }

  let(:tiff_content) { File.open(tiff_file, "r", &:read) }
  let(:pdf_content) { File.open(pdf_file, "r", &:read) }

  let(:fake_pdf_content) { "From VBMS" }

  context "#content" do
    let(:save_document_metadata) { true }
    subject { document.fetcher.content(save_document_metadata: save_document_metadata) }

    context "when file is in S3" do
      before do
        allow(S3Service).to receive(:fetch_content).with("#{document.document_id}.pdf").and_return("hello there")
      end

      it "should return the content from S3 and should not update the DB" do
        expect(subject).to eq "hello there"
        expect(document.started_at).to_not eq nil
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
        expect(document.reload).to_not eq nil
        expect(document.started_at).to_not eq nil
      end

      context "when save_document_metadata is false" do
        let(:save_document_metadata) { false }
        it "should not update DB when save_document_metadata is false" do
          subject
          expect(document.started_at).to eq nil
        end
      end

      context "when VBMS returns a tiff file" do
        let(:document) do
          download.documents.build(
            id: "1234",
            document_id: "{3333-3333}",
            received_at: Time.utc(2015, 9, 6, 1, 0, 0),
            type_id: "825",
            mime_type: "image/tiff"
          )
        end

        before do
          allow(Fakes::DocumentService).to receive(:fetch_document_file).and_return(tiff_content)
        end

        it "should convert the tiff to pdf and return it" do
          # This method strips dates from the PDF file since these change on each conversion.
          def strip_dates(string)
            string = string.scrub.sub(/CreationDate \(D:\d*\)/, 'CreationDate')
            string.scrub.sub(/ModDate \(D:\d*\)/, 'ModDate')
          end

          expect(strip_dates(subject)).to eq strip_dates(pdf_content)
          expect(document.reload.mime_type).to eq "image/tiff"
          expect(document.converted_mime_type).to eq "application/pdf"
        end
      end
    end

    context "when the file is in s3 after it has been cached" do
      before do
        allow(S3Service).to receive(:fetch_content).and_return(nil)
        allow(Fakes::DocumentService).to receive(:fetch_document_file).and_return(fake_pdf_content)
      end

      it "should cache in s3 from VBMS and then serve from s3" do
        expect(subject).to eq fake_pdf_content
        allow(S3Service).to receive(:fetch_content).and_return("from s3")
        expect(document.fetcher.content).to eq "from s3"
      end
    end
  end
end
