require "rails_helper"

RSpec.feature "Start download" do
	it "shows me the search page" do
		visit '/'
		expect(page).to have_content 'Welcome to eFolder Express!'
	end
end