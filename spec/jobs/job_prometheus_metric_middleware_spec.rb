# frozen_string_literal: true

describe JobPrometheusMetricMiddleware do
  before do
    @middleware = JobPrometheusMetricMiddleware.new

    @msg = {
      "args" => [{
        "job_class" => "FunTestJob"
      }]
    }
    @yield_called = false
    allow(PrometheusService).to receive(:push_metrics!).and_return(nil)
    @labels = { name: "FunTestJob" }
  end

  context ".call" do
    let(:call) { @middleware.call(nil, @msg, :default) { @yield_called = true } }

    it "always increments attempts counter" do
      attempt_cnt_before = PrometheusService.background_jobs_attempt_counter.values[@labels]

      expect(@yield_called).to be_falsey
      call
      expect(@yield_called).to be_truthy
      expect(PrometheusService.background_jobs_attempt_counter.values[@labels]).to eq(attempt_cnt_before.to_f + 1)
    end

    it "increments error counter on error" do
      err_msg = "test"

      expect(PrometheusService.background_jobs_error_counter.values[@labels]).to eq(nil)
      expect do
        @middleware.call(nil, @msg, :default) { raise(err_msg) }
      end.to raise_error(err_msg)

      expect(PrometheusService.background_jobs_error_counter.values[@labels]).to eq(1)
    end
  end
end
