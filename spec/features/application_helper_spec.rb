require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#current_ga_path" do
    it "returns route's path without resource ids" do
      helper.request.env["PATH_INFO"] = "/downloads/5/download"
      expect(helper.current_ga_path).to eq "/application/serve_single_page_app"
    end
  end
end
