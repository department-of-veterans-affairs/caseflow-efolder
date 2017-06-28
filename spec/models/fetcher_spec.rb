describe Fetcher do
  before do
    Download.bgs_service = Fakes::BGSService
  end

  let(:download) { Download.create(file_number: "21012") }
  let(:document) do
    download.documents.build(
      document_id: "{3333-3333}",
      received_at: Time.utc(2015, 9, 6, 1, 0, 0),
      type_id: "825",
      mime_type: "application/pdf"
    )
  end

  context "#content" do
    subject { document.fetcher.content }

    context "when file is in S3" do
      before do
        allow(S3Service).to receive(:fetch_content).and_return("hello there")
      end

      it "should return the content from S3" do
        expect(subject).to eq "hello there"
      end
    end

    context "when file is not in S3" do
      before do
        allow(S3Service).to receive(:fetch_content).and_return(nil)
        allow(Fakes::DocumentService).to receive(:fetch_document_file).and_return("from VBMS")
      end

      it "should return the content from VBMS" do
        expect(subject).to eq "from VBMS"
      end
    end
  end

  context "#stream" do
    subject { document.fetcher.stream }

    context "when file is in S3" do
      before do
        allow(S3Service).to receive(:stream_content).and_return("hello there")
      end

      it "should return the content from S3" do
        expect(subject).to eq "hello there"
      end
    end

    context "when file is not in S3" do
      before do
        allow(S3Service).to receive(:stream_content).and_return(nil)
        allow(Fakes::DocumentService).to receive(:fetch_document_file).and_return("from VBMS")
      end

      it "should return the content from VBMS" do
        expect(subject).to eq "from VBMS"
      end
    end
  end
end