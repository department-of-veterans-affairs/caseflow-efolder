describe ExceptionLogger do
  subject { ExceptionLogger.capture(error) }

  context ".capture" do
    before do
      allow(Raven).to receive(:capture_exception)
    end
    context "when external system is in maintenance mode" do
      let(:error) { OpenStruct.new(message: "Maintenance - VBMS", backtrace: []) }

      it "should not log error in Sentry" do
        subject
        expect(Raven).to_not have_received(:capture_exception)
      end
    end

    context "when external system is not in maintenance mode" do
      let(:error) { OpenStruct.new(message: "Some other error", backtrace: []) }

      it "should log error in Sentry" do
        subject
        expect(Raven).to have_received(:capture_exception)
      end
    end

    context "when error is ignorable" do
      let(:error) { BGS::ShareError.new("Connection reset by peer") }

      it "does not log error in Sentry" do
        subject
        expect(Raven).to_not have_received(:capture_exception)
      end
    end
  end
end
