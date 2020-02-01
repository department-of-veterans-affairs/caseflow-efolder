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

  context "happy path" do
    it 'uses external SAML IdP' do
      expect(User.count).to eq 0

      get '/'
      expect(response).to redirect_to(/auth\/samlva/)

      # manually follow the redirect
      get '/auth/samlva'
      expect(response).to redirect_to(/idp.example.com/)

      idp_uri = URI(response.headers['Location'])
      saml_idp_resp = Net::HTTP.get(idp_uri)

      resp_xml = Base64.decode64(saml_idp_resp)

      expect(resp_xml).to match(
        /<NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">other@example.com/
      )

      post '/auth/saml_callback', params: { SAMLResponse: saml_idp_resp }

      expect(response).to redirect_to('http://efolder.example.com/')
      user = session["user"]
      expect(user).to_not be_nil
      expect(user["id"]).to eq "ACCOUNT_NAME" # only attribute from SAML we keep.

      # we prefer all the other attributes via BGS common security service,
      # and we ignore most of what was in the SAML response.
      # In reality these are identical most of the time, so here we are just
      # exercising our application logic to verify where our canonical values derive.
      # So, e.g., the NameID email will not equal the email from BGS.
      expect(user["email"]).to eq "jane.doe@example.com"
      expect(user["name"]).to eq "Jane Doe"
      expect(user["css_id"]).to eq "BVADOEJANE"
      expect(user["roles"]).to eq ["Download eFolder", "Establish Claim"]
      expect(user["station_id"]).to eq "101"
    end
  end
end
