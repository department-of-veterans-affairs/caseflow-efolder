# frozen_string_literal: true

describe DependencyError do
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

  describe ".from_dependency_error" do
    let(:bgs_error) { BGS::ShareError.new("Connection timed out - connect(2) for \"bepprod.vba.va.gov\" port 443") }
    let(:vbms_error) { VBMS::HTTPError.new(500, "HTTPClient::ReceiveTimeoutError: execution expired") }
    let(:http_error) { HTTPClient::ReceiveTimeoutError.new("execution expired") }

    it "re-casts BGS exception" do
      expect(BGSError.from_dependency_error(bgs_error)).to be_a(BGSError::Transient)
    end

    it "re-casts VBMS exception" do
      expect(VBMSError.from_dependency_error(vbms_error)).to be_a(VBMSError::Transient)
    end

    it "re-casts HTTP exception" do
      expect(VBMSError.from_dependency_error(http_error)).to be_a(VBMSError::Transient)
    end
  end
end
