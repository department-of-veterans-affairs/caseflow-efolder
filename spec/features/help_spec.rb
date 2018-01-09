RSpec.feature "Help" do
  scenario "Visiting the Help/FAQ page" do
    User.authenticate!

    visit("/")
    click_on "first last"
    expect(page).to have_content("Help")

    # rubocop:disable Lint/HandleExceptions
    begin
      click_on "Help"
    rescue Capybara::Poltergeist::JavascriptError
      # Embedding YouTube Links can cause JavaScript Errors on browsers that don't
      # support HTML5 video. Since it's unrelated to our code, ignore this JS error.
    end
    # rubocop:enable Lint/HandleExceptions
    expect(page).to have_content("Frequently Asked Questions")
  end
end
