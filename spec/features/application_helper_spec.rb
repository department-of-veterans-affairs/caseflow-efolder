require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#current_ga_path" do
    it "returns route's path without resource ids" do
      helper.request.env["PATH_INFO"] = "/downloads/5/download"
      expect(helper.current_ga_path).to eq "/application/serve_single_page_app"
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
