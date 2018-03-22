require "rails_helper"

RSpec.feature "Downloads" do
  include ActiveJob::TestHelper

  let(:documents) do
    [
      OpenStruct.new(
        document_id: "1",
        series_id: "1234",
        type_id: Caseflow::DocumentTypes::TYPES.keys.sample,
        version: "1",
        mime_type: "txt",
        received_at: Time.now.utc
      ),
      OpenStruct.new(
        document_id: "2",
        series_id: "5678",
        type_id: Caseflow::DocumentTypes::TYPES.keys.sample,
        version: "1",
        mime_type: "txt",
        received_at: Time.now.utc
      )
    ]
  end

  let(:invalid_veteran_id) { "abcd" }

  let(:veteran_id) { "12341234" }
  let(:veteran_info) do
    {
      "veteran_first_name" => "Stan",
      "veteran_last_name" => "Lee",
      "veteran_last_four_ssn" => "2222"
    }
  end

  before do
    @user = User.create(css_id: "123123", station_id: "116")

    FeatureToggle.enable!(:efolder_react_app)

    User.authenticate!

    allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info).with(veteran_id).and_return(veteran_info)
    allow_any_instance_of(Fakes::BGSService).to receive(:valid_file_number?).with(veteran_id).and_return(true)
    allow_any_instance_of(Fakes::BGSService).to receive(:valid_file_number?).with(invalid_veteran_id).and_return(false)

    allow(Fakes::DocumentService).to receive(:v2_fetch_documents_for).and_return(documents)
    allow(Fakes::DocumentService).to receive(:v2_fetch_document_file).and_return("Test content")

    S3Service.files = {}

    allow(S3Service).to receive(:stream_content).and_return("streamed content")

    DownloadHelpers.clear_downloads
  end

  after do
    FeatureToggle.disable!(:efolder_react_app)
  end

  scenario "Extraneous spaces in search input" do
    visit "/"

    fill_in "Search for a Veteran ID number below to get started.", with: " #{veteran_id} "
    click_button "Search"

    expect(page).to have_content "STAN LEE VETERAN ID #{veteran_id}"

    expect(Manifest.where(file_number: veteran_id).count).to eq(1)
  end

  scenario "Requesting invalid case number" do
    visit "/"

    fill_in "Search for a Veteran ID number below to get started.", with: invalid_veteran_id
    click_button "Search"

    expect(page).to have_content("File number is invalid")
  end

  context "When veteran_id has no veteran info" do
    before do
      allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info).with(veteran_id).and_return(nil)
    end

    scenario "Requesting veteran_id returns cannot find eFolder" do
      visit "/"
      fill_in "Search for a Veteran ID number below to get started.", with: veteran_id

      click_button "Search"
      expect(page).to have_content("could not find an eFolder with the Veteran ID")
    end
  end

  context "When veteran id has high sensitivity" do
    before do
      allow_any_instance_of(Fakes::BGSService).to receive(:sensitive_files).and_return(veteran_id => true)
    end

    scenario "Cannot access it" do
      visit "/"
      fill_in "Search for a Veteran ID number below to get started.", with: veteran_id
      click_button "Search"

      expect(page).to have_content("contains sensitive information")
    end
  end

  context "When veteran case folder has no documents" do
    before do
      allow(Fakes::DocumentService).to receive(:v2_fetch_documents_for).and_return([])
    end

    scenario "Download with no documents" do
      perform_enqueued_jobs do
        visit "/"
        fill_in "Search for a Veteran ID number below to get started.", with: veteran_id
        click_button "Search"

        expect(page).to have_css ".cf-msg-screen-heading", text: "No Documents in eFolder"
        expect(page).to have_content veteran_id

        click_on "search again"
        expect(page).to have_current_path(root_path)
      end
    end
  end
end
