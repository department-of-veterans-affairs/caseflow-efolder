describe ApplicationJob do
  class MyJob < ApplicationJob
    def perform
      Raven.extra_context(foo: :bar)
      over_ride_me
    end

    def over_ride_me
      @over_ride_me_called = true
    end
  end

  class IgnorableError < StandardError
    def ignorable?
      true
    end
  end

  describe "#perform_now" do
    subject { MyJob.perform_now }

    context "when an error is raised" do
      before do
        @exceptions_allowed = {}

        allow_any_instance_of(MyJob).to receive(:over_ride_me).and_raise(http_error)
        allow(Raven).to receive(:capture_exception).and_wrap_original do |method, *args|
          exception = args.first
          @raven_error = exception
          @raven_extra ||= Raven.context.extra
          @exceptions_allowed[exception.class.name] = Raven.configuration.exception_class_allowed?(exception)
          method.call(*args)
        end
        # mock DSN to allow configuration to resemble config/initializers/sentry.rb
        Raven.configure do |config|
          config.dsn = "http://foo:bar@example.com/123"
          config.excluded_exceptions += [
            "HTTPClient::ReceiveTimeoutError",
            "HTTPClient::KeepAliveDisconnected"
          ]
          config.should_capture = lambda { |exc_or_msg| !exc_or_msg.try(:ignorable?) }
          logger = Logger.new(string_log)
          config.logger = logger
        end
      end

      after do
        # "reset" the dsn value so other tests do not attempt to send to sentry
        Raven.configure do |config|
          config.server = nil
          config.host = nil
        end
      end

      let(:string_log) { StringIO.new }

      context "when error is on exclude list" do
        let(:http_error) { HTTPClient::ReceiveTimeoutError.new "execution expired" }

        it "is logged only" do
          expect { subject }.to raise_error(http_error)
          expect(Raven).to have_received(:capture_exception).once
          expect(@raven_error).to be_a(HTTPClient::ReceiveTimeoutError)
          expect(@raven_extra[:foo]).to eq(:bar)
          expect(@exceptions_allowed).to eq("HTTPClient::ReceiveTimeoutError" => false)
          string_log.rewind
          expect(string_log.read).to match(/User excluded error: #<HTTPClient::ReceiveTimeoutError: execution expired>/)
        end
      end

      context "when error is ignorable" do
        let(:http_error) { IgnorableError.new "oops" }

        it "is logged only" do
          expect { subject }.to raise_error(http_error)
          expect(Raven).to have_received(:capture_exception).once
          expect(@raven_error).to be_a(IgnorableError)
          expect(@raven_extra[:foo]).to eq(:bar)
          expect(@exceptions_allowed).to eq("IgnorableError" => true)
          string_log.rewind
          expect(string_log.read).to match(/oops excluded from capture: should_capture returned false/)
        end
      end

      context "when error should be reported" do
        let(:http_error) { StandardError.new "bad things!" }

        before do
          stub_request(:post, "http://example.com/api/123/store/").to_return(body: "ok", status: 200)
        end

        it "logs to Rails and Raven" do
          expect { subject }.to raise_error(http_error)
          expect(Raven).to have_received(:capture_exception).once
          expect(@raven_error.class).to eq StandardError
          expect(@raven_extra[:foo]).to eq(:bar)
          expect(@exceptions_allowed).to eq("StandardError" => true)
          string_log.rewind
          expect(string_log.read).to match(/Sending event \w+ to Sentry/)
        end
      end
    end
  end
end
