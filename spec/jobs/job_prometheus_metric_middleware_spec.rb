describe JobPrometheusMetricMiddleware do
  before do
    @middleware = JobPrometheusMetricMiddleware.new

    @yield_called = false
    allow(PrometheusService).to receive(:push_metrics!).and_return(nil)
  end

  let(:job_class) { "FunTestJob" }
  let(:body) do
    {
      "job_class" => job_class
    }
  end
  let(:labels) do
    {
      name: job_class
    }
  end

  context ".call" do
    let(:call) { @middleware.call(nil, nil, :default, body) { @yield_called = true } }

    it "always increments attempts counter" do
      attempt_cnt_before = PrometheusService.background_jobs_attempt_counter.values[labels]

      expect(@yield_called).to be_falsey
      call
      expect(@yield_called).to be_truthy
      expect(PrometheusService.background_jobs_attempt_counter.values[labels]).to eq(attempt_cnt_before.to_f + 1)
    end

    it "increments error counter on error" do
      err_msg = "test"

      expect(PrometheusService.background_jobs_error_counter.values[labels]).to eq(nil)
      expect do
        @middleware.call(nil, nil, :default, body) { raise(err_msg) }
      end.to raise_error(err_msg)

      expect(PrometheusService.background_jobs_error_counter.values[labels]).to eq(1)
    end
  end
end
