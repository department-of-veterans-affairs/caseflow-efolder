require "rails_helper"

describe Document do
  context ".new" do
    subject { Document.new }
    it "defaults vbms_filename to empty string" do
      expect(subject.vbms_filename).to eq("")
    end
  end

  context "#s3_filename" do
    subject { document.s3_filename }

    let(:document) do
      Document.new(vbms_filename: "keep-stamping.pdf", mime_type: "application/pdf", download_id: 45)
    end

    it { is_expected.to eq("45-#{document.id}-keep-stamping.pdf") }
  end

  context "#filename" do
    subject { document.filename }

    context "all the components are present" do
      let(:document) do
        Document.new(
          vbms_filename: "purple.txt",
          received_at: Time.utc(2015, 1, 3, 17, 0, 0),
          doc_type: "99",
          document_id: "{ABC123-DEF123-GHI456}",
          mime_type: "application/pdf"
        )
      end

      it { is_expected.to eq("VA 10-1000 Hospital Summary andor the Compensation and Pension Exam Report-20150103-ABC123-DEF123-GHI456.pdf") }
    end
  end
end
