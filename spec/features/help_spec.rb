RSpec.feature "Help" do
  scenario "Visiting the Help/FAQ page" do
    User.authenticate!
    visit("/")
    puts page.body
    click_on "first last"
    expect(page).to have_content("Help")
    click_on "Help"
    expect(page).to have_content("Frequently Asked Questions")
  end
end
