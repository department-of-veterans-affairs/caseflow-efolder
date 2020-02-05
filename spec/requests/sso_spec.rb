describe 'SSO' do
  before do
    FeatureToggle.enable!(:use_ssoi_iam)
  end
  after do
    FeatureToggle.disable!(:use_ssoi_iam)
  end

  before do
    host! "efolder.example.com"
  end

  def saml_idp_handshake(insert_error = false)
    get '/auth/samlva'
    expect(response).to redirect_to(/idp.example.com/)

    idp_uri = URI(response.headers['Location'])
    saml_idp_resp = Net::HTTP.get(idp_uri)
    resp_xml = Base64.decode64(saml_idp_resp)
    expect(resp_xml).to match(
      /<NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">other@example.com/
    )

    if insert_error
      new_xml = resp_xml.gsub(
        /NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"/,
        'NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"'
      )
      saml_idp_resp = Base64.encode64(new_xml)
    end

    post '/auth/saml_callback', params: { SAMLResponse: saml_idp_resp }
  end

  def expect_redirect_to_login_with_error(error)
    expect(response).to redirect_to("http://efolder.example.com/login")
    expect(flash[:error]).to_not be_nil
  end

  context "happy path" do
    it 'uses external SAML IdP' do
      get "/"
      expect(response).to redirect_to("/login")

      get "/login"
      expect(response).to be_successful

      # fill out the form
      post "/login", params: { username: "ACCOUNT_NAME", station_id: "" }
      expect(response).to redirect_to(/auth\/samlva/)

      saml_idp_handshake

      expect(response).to redirect_to('http://efolder.example.com/')

      user = session["user"]
      expect(user).to_not be_nil
      expect(user["id"]).to eq "ACCOUNT_NAME" # only attribute from SAML we keep.

      # we prefer all the other attributes via BGS common security service,
      # and we ignore most of what was in the SAML response.
      # In reality these are identical most of the time, so here we are just
      # exercising our application logic to verify where our canonical values derive.
      # So, e.g., the NameID email will not equal the email from BGS.
      expect(user["email"]).to eq "first.last@test.gov"
      expect(user["name"]).to eq "First Last"
      expect(user["css_id"]).to eq "BVALASTFIRST"
      expect(user["roles"]).to eq ["Download eFolder", "Establish Claim"]
      expect(user["station_id"]).to eq "101"

      # view our session dump
      get "/me"

      expect(response).to be_successful
      expect(response.body).to match /#{user['email']}/

      # finally, log out
      get "/logout"

      expect(response).to redirect_to("/")
      expect(session["user"]).to be_nil
    end
  end

  context "user starts on /login page" do
    it "ends up on / page" do
      get "/login"
      session["redirect_to"] = "/login"
      post "/login"
      saml_idp_handshake
      expect(response).to redirect_to("/")
    end
  end

  context "assert test username" do
    it "prefers what user enters into form" do
      post "/login", params: { username: "foobar" }
      saml_idp_handshake
      user = session["user"]

      expect(user).to_not be_nil
      expect(user["id"]).to eq "foobar"
    end
  end

  context "auth/failure" do
    it "sets error, redirects" do
      get "/auth/failure?message=oops"

      expect(response).to redirect_to("/login")
      expect(flash[:error]).to_not be_nil
    end
  end

  context "bad SAMLResponse" do
    it "redirects to /login with error message" do
      post "/login"
      saml_idp_handshake(true)

      expect(response).to redirect_to(/auth\/failure/)

      get response.location
      expect(response).to redirect_to("/login")
      expect(flash[:error]).to_not be_nil
    end
  end

  context "running production" do
    before do
      allow(Rails).to receive(:deploy_env?).with(:prod) { true }
    end

    it "ignores username field" do
      get "/login"

      expect(response.body).to_not match(/Username/)

      post "/login", params: { username: "foobar" }
      saml_idp_handshake
      user = session["user"]

      expect(user).to_not be_nil
      expect(user["id"]).to eq "ACCOUNT_NAME"
    end
  end

  context "user has multiple stations" do
    it "requires station assertion" do
      post "/login", params: { username: "multiple-stations", station_id: "" }
      saml_idp_handshake

      expect_redirect_to_login_with_error(BGS::StationAssertionRequired)
    end
  end

  context "unhappy paths" do
    context "invalid username" do
      it "disallows authorization" do
        get "/login"
        expect(response).to be_successful

        post "/login", params: { username: "invalid", station_id: "" }
        expect(response).to redirect_to(/auth\/samlva/)

        saml_idp_handshake

        expect_redirect_to_login_with_error(BGS::InvalidUsername)
      end
    end

    context "invalid station" do
      it "disallows authorization" do
        get "/login"
        expect(response).to be_successful

        post "/login", params: { username: "", station_id: "invalid" }
        expect(response).to redirect_to(/auth\/samlva/)

        saml_idp_handshake

        expect_redirect_to_login_with_error(BGS::InvalidStation)
      end
    end
  end
end
