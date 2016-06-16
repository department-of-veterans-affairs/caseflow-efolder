require "rails_helper"

describe Document do
  context "#s3_filename" do
    subject { document.s3_filename }

    let(:document) do
      Document.new(vbms_filename: "keep-stamping.pdf", mime_type: "application/pdf", download_id: 45)
    end

    it { is_expected.to eq("45-#{document.id}-keep-stamping.pdf") }
  end

  context "#filename" do
    subject { document.filename }

    context "uses the preferred extension of the mime type" do
      let(:document) { Document.new(vbms_filename: "purple.txt", mime_type: "application/pdf") }
      it { is_expected.to eq("purple.pdf") }
    end
  end
end
