describe SessionsController do
  describe "#login" do
    it "returns login form" do
      get :login

      expect(response).to be_successful
    end

    context "when already authenticated" do
      it "redirects to root" do
        allow(controller).to receive(:current_user) { true }

        get :login

        expect(response).to redirect_to "/"
      end
    end

    context "request asks for JSON response" do
      it "returns 200 response with error message" do
        get :login, as: :json

        expect(response).to be_successful
        expect(JSON.parse(response.body)).to eq({ "error" => "JSON not supported" })
      end
    end

    context "requests asks for text response" do
      it "returns 200 response with error message" do
        get :login, as: :text

        expect(response).to be_successful
        expect(response.body).to eq "Text not supported"
      end
    end
  end

  describe "#login_creds" do
    it "captures username/station_id" do
      post :login_creds, params: { username: "foo", station_id: "123" }

      expect(response).to redirect_to "/auth/samlva"
      expect(session["login"]).to eq("username" => "foo", "station_id" => "123")
    end
  end

  describe "#create" do
    # other tests in spec/requests/sso where we have the FakeSamlIdp available.
    it "requires SAMLRequest param" do
      post :create

      expect(response).to redirect_to "/login"
      expect(flash[:error]).to be_a(SessionsController::MissingSAMLRequest)
    end
  end

  describe "#destroy" do
    before do
      User.authenticate!
      session["user"] = { css_id: "foo" }
    end

    after { User.unauthenticate! }

    it "resets the session" do
      expect(session["user"]).to_not be_nil

      get :destroy

      expect(response).to redirect_to "/"
      expect(session["user"]).to be_nil
      expect(RequestStore[:current_user]).to be_nil
    end 
  end

  describe "#me" do
    before { User.authenticate! }
    after { User.unauthenticate! }

    it "returns HTML of session dump" do
      get :me

      expect(response).to be_successful
    end
  end
end
