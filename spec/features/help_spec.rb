RSpec.feature "Help" do
  scenario "Visiting the Help/FAQ page" do
    User.authenticate!

    visit("/")
    click_on "First Last"
    expect(page).to have_content("Help")

      # rubocop:disable Lint/HandleExceptions
    begin
      click_on "Help"
    end
    # rubocop:enable Lint/HandleExceptions
    expect(page).to have_content("Frequently Asked Answers")
  end
end
