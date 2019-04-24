# frozen_string_literal: true

describe BGSError do
  describe "#new" do
    it "preserves backtrace" do
      trace = %w[foo bar]
      orig_error = StandardError.new("oop!")
      orig_error.set_backtrace(trace)

      bgs_error = described_class.new(orig_error)

      expect(bgs_error.message).to eq("oop!")
      expect(bgs_error.backtrace).to eq(trace)
    end

    it "copies over body" do
      orig_error = BGS::ShareError.new("oops")
      bgs_error = described_class.new(orig_error)

      expect(bgs_error.message).to eq("oops")
    end
  end

  describe ".from_bgs_error" do
    subject { described_class.from_bgs_error(error) }
    let(:error) { BGS::ShareError.new("Connection timed out - connect(2) for \"bepprod.vba.va.gov\" port 443") }

    it "re-casts the exception" do
      expect(subject).to be_a(TransientBGSError)
    end
  end
end