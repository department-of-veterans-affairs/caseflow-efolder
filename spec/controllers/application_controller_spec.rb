describe ApplicationController do
  describe "#serve_single_page_app" do
    render_views

    let!(:user) { User.authenticate! }

    subject { get :serve_single_page_app, as: request_format }

    context "HTML" do
      let(:request_format) { :html }

      it "returns React bootstrap response" do
        subject

        expect(response).to be_successful
        expect(response.body).to match(/efolderExpress.init/)
      end
    end

    context "text" do
      let(:request_format) { :text }

      it "returns (mostly) empty response" do
        subject

        expect(response).to be_successful
        expect(response.body).to eq "Text not supported"
      end
    end

    context "JSON" do
      let(:request_format) { :json }

      it "returns JSON payload with error message" do
        subject

        expect(response).to be_successful
        expect(JSON.parse(response.body)).to eq({ "error" => "JSON not supported" })
      end
    end
  end
end
