describe "Health Check API" do
  context "mock" do
    before do
      Rails.application.config.build_version = { deployed_at: "the best day ever" }
      FakeWeb.allow_net_connect = false
    end

    after { FakeWeb.allow_net_connect = true }
    
    context "pushgateway offline" do
      it "passes health check" do
        expect_unhealty
      end

      context "caseflow out of service" do
        before { Rails.cache.write("out_of_service", true) }
        after { Rails.cache.write("out_of_service", false) }
        
        it "passes health check" do
          expect_unhealty
        end
      end
    end
    
    
    context "pushgateway unhealthy" do
      before do
        FakeWeb.register_uri(
          :get, "http://127.0.0.1:9091/-/healthy",
          body: "Error",
          status: ["503", "Service Unavailable"]
        )
      end

      after { FakeWeb.clean_registry }

      it "fails health check" do
        expect_unhealty
      end

      context "caseflow out of service" do
        before { Rails.cache.write("out_of_service", true) }
        after { Rails.cache.write("out_of_service", false) }
        
        it "fails health check" do
          expect_unhealty
        end
      end
    end

    context "pushgateway healthy" do
      before do
        FakeWeb.register_uri(
          :get, "http://127.0.0.1:9091/-/healthy",
          body: "OK"
        )
      end

      after { FakeWeb.clean_registry }

      it "passes health check" do
        expect_healthy
      end

      context "caseflow out of service" do
        before { Rails.cache.write("out_of_service", true) }
        after { Rails.cache.write("out_of_service", false) }
        
        it "passes health check" do
          expect_healthy
        end
      end
    end
  end

  def expect_healthy
    get "/health-check"

    expect(response).to be_success

    json = JSON.parse(response.body)
    expect(json["healthy"]).to eq(true)
    expect(json["deployed_at"]).to eq("the best day ever")
  end

  def expect_unhealty
    get "/health-check"

    expect(response).to have_http_status(503)

    json = JSON.parse(response.body)
    expect(json["healthy"]).to eq(false)
    expect(json["deployed_at"]).to eq("the best day ever")
  end
end
