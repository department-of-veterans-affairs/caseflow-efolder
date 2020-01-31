describe 'SSO' do
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

    binding.pry

    expect(resp_xml).to match(
      /<NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">other@example.com/
    )

    post '/auth/saml_callback', params: { SAMLResponse: saml_idp_resp }

    expect(response).to redirect_to('http://www.example.com/')
    expect(User.count).to eq 1
  end
end
