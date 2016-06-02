require "rails_helper"

describe Document do
  context "#filename" do
    subject { document.filename }

    context "uses the preferred extension of the mime type" do
      let(:document) { Document.new(vbms_filename: "purple.txt", mime_type: "application/pdf") }
      it { is_expected.to eq("purple.pdf") }
    end
  end
end
