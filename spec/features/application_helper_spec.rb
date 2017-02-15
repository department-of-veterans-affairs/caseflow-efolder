require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#current_ga_path" do
    it "returns route's path without resource ids" do
      helper.request.env["PATH_INFO"] = "/downloads/5/download"
      expect(helper.current_ga_path).to eq "/downloads/download"
    end
  end

  describe "#loading_pill" do
    describe "by default" do
      it "creates a pill labeled \"Loading...\"" do
        expect(helper.loading_pill).to include "Loading..."
      end

      it "creates a spinning icon" do
        expect(helper.loading_pill).to have_css(".ee-pill-icon-loading-front")
      end
    end

    describe "with options[:text]" do
      it "sets the pill's label" do
        expect(helper.loading_pill(text: "Working...")).to include "Working..."
      end
    end

    describe "with options[:no_icon]" do
      it "omits the spinning icon" do
        expect(helper.loading_pill(no_icon: true)).not_to have_css(".ee-pill-icon-loading-front")
      end
    end
  end
end
