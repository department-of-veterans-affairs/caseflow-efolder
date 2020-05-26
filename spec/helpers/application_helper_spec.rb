require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#current_ga_path" do
    let(:full_path) { "/downloads/5/download" }

    before do
      helper.request.env["PATH_INFO"] = full_path
    end

    it "returns route's path without resource ids" do
      expect(helper.current_ga_path).to eq "/application/serve_single_page_app"
    end

    context "routing error" do
      before do
        routes = double("routes")
        allow(routes).to receive(:recognize_path).with(full_path)
          .and_raise(ActionController::RoutingError.new("oops"))
        allow(Rails.application).to receive(:routes) { routes }
      end

      it "returns full path" do
        expect(helper.current_ga_path).to eq full_path
      end
    end
  end

  describe "#ui_user?" do
    subject { helper.ui_user? }

    context "user logged in" do
      before { User.authenticate!(roles: ["Download eFolder"]) }
      after { RequestStore[:current_user] = false }

      it { is_expected.to eq true }
    end

    context "user not logged in" do
      it { is_expected.to eq false }
    end
  end
end
