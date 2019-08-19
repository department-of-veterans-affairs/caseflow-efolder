require "rails_helper"

RSpec.feature "Backend Error Flows" do
  include ActiveJob::TestHelper

  let(:documents) do
    [
      OpenStruct.new(
        document_id: SecureRandom.base64,
        series_id: "1234",
        type_id: Caseflow::DocumentTypes::TYPES.keys.sample,
        version: "1",
        mime_type: "txt",
        received_at: Time.now.utc
      ),
      OpenStruct.new(
        document_id: SecureRandom.base64,
        series_id: "5678",
        type_id: Caseflow::DocumentTypes::TYPES.keys.sample,
        version: "1",
        mime_type: "txt",
        received_at: Time.now.utc
      )
    ]
  end

  let(:veteran_id) { "12341234" }
  let(:veteran_info) do
    {
      "file_number" => veteran_id,
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
    allow_any_instance_of(Fakes::BGSService).to receive(:record_found?).with(veteran_info).and_return(true)

    allow(Fakes::VBMSService).to receive(:v2_fetch_documents_for).and_return(documents)
    allow(Fakes::VVAService).to receive(:v2_fetch_documents_for).and_return([])
    allow(Fakes::DocumentService).to receive(:v2_fetch_document_file).and_return("Test content")

    S3Service.files = {}

    allow(S3Service).to receive(:stream_content).and_return("streamed content")

    DownloadHelpers.clear_downloads
  end

  after do
    FeatureToggle.disable!(:efolder_react_app)
  end

  # context "When VBMS returns an error" do
  #   before do
  #     allow(Fakes::VBMSService).to receive(:v2_fetch_documents_for).and_raise(VBMS::ClientError)
  #     allow(Fakes::VVAService).to receive(:v2_fetch_documents_for).and_return(documents)
  #   end

  #   scenario "Download with VBMS connection error" do
  #     perform_enqueued_jobs do
  #       visit "/"
  #       fill_in "Search for a Veteran ID number below to get started.", with: veteran_id
  #       click_button "Search"

  #       expect(page).to have_content "We are having trouble connecting to VBMS"
  #       expect(page).to have_css ".usa-alert-heading", text: "We are having trouble connecting to VBMS"
  #       expect(page).to have_content Caseflow::DocumentTypes::TYPES[documents[0].type_id]

  #       click_link "Back to eFolder Express"

  #       expect(page).to have_current_path("/")
  #     end
  #   end
  # end

  context "When VVA returns an error" do
    before do
      allow(Fakes::VVAService).to receive(:v2_fetch_documents_for).and_raise(VVA::ClientError)
      allow(Fakes::VBMSService).to receive(:v2_fetch_documents_for).and_return(documents)
    end

    scenario "Download with VVA connection error" do
      perform_enqueued_jobs do
        visit "/"
        fill_in "Search for a Veteran ID number below to get started.", with: veteran_id
        click_button "Search"

        expect(page).to have_css ".usa-alert-heading", text: "We are having trouble connecting to VVA"
        expect(page).to have_content Caseflow::DocumentTypes::TYPES[documents[0].type_id]

        click_link "Back to eFolder Express"

        expect(page).to have_current_path("/")
      end
    end
  end

  context "When at least one document fails" do
    before do
      allow(Fakes::DocumentService).to receive(:v2_fetch_document_file) do |arg|
        case arg.id
        when 1
          raise VBMS::ClientError
        else
          "Test content"
        end
      end
    end

    scenario "Download the eFolder anyway" do
      perform_enqueued_jobs do
        visit "/"
        fill_in "Search for a Veteran ID number below to get started.", with: veteran_id

        click_button "Search"

        expect(page).to have_content "STAN LEE VETERAN ID #{veteran_id}"
        expect(page).to have_content "Start retrieving efolder"

        within(".cf-app-segment--alt") do
          click_button "Start retrieving efolder"
        end

        expect(page).to have_css ".cf-tab.cf-active", text: "Errors (1)"
        expect(page).to have_content "Some files could not be retrieved"

        expect(page).to have_content Caseflow::DocumentTypes::TYPES[documents[0].type_id]

        # Clicking on progress shouldn't change tabs since there number is 0.
        click_on "Progress (0)"
        expect(page).to have_content Caseflow::DocumentTypes::TYPES[documents[0].type_id]

        click_on "Completed (1)"
        expect(page).to have_content Caseflow::DocumentTypes::TYPES[documents[1].type_id]

        within first(".usa-alert-body") do
          click_on "Download anyway"
        end
        expect(page).to have_selector("#confirm-download-anyway")

        within first(".cf-modal-body") do
          click_on "Download anyway"
        end

        DownloadHelpers.wait_for_download
        download = DownloadHelpers.downloaded?
        expect(download).to be_truthy

        expect(DownloadHelpers.download).to include("Lee, Stan - 2222")

        click_on "Start over"

        click_on "Recent downloads"

        history_row = "#download-1"

        expect(find(history_row)).to have_content(veteran_id)
        expect(find(history_row)).to have_css(".cf-icon-alert")
        within(history_row) { click_on("View results") }
        expect(page).to have_content("Download anyway")
      end
    end

    scenario "Retrying to download error-ed document succeeds" do
      perform_enqueued_jobs do
        visit "/"
        fill_in "Search for a Veteran ID number below to get started.", with: veteran_id

        click_button "Search"

        expect(page).to have_content "STAN LEE VETERAN ID #{veteran_id}"
        expect(page).to have_content "Start retrieving efolder"

        within(".cf-app-segment--alt") do
          click_button "Start retrieving efolder"
        end

        expect(page).to have_css ".cf-tab.cf-active", text: "Errors (1)"
        expect(page).to have_content "Some files could not be retrieved"

        allow(Fakes::DocumentService).to receive(:v2_fetch_document_file).and_return("Test content")
        within first(".usa-alert-body") do
          click_on "Retry missing files"
        end
        expect(page).to have_content("Success!")
      end
    end
  end

  context "When manifest has failed status" do
    let!(:manifest) { Manifest.create(file_number: veteran_id, fetched_files_status: "failed") }
    let!(:source) do
      [
        manifest.sources.create(status: :success, name: "VBMS"),
        manifest.sources.create(status: :success, name: "VVA")
      ]
    end
    let!(:files_download) do
      manifest.files_downloads.find_or_create_by(
        user: User.first,
        requested_zip_at: Time.zone.now
      )
    end

    scenario "Download progress shows correct information" do
      visit "/downloads/1"

      expect(page).to have_css ".usa-alert-heading", text: "There was an error downloading this efolder"
      expect(page).to have_content "You can try to download this efolder again"

      click_on "Retry download"

      expect(page).to have_content "Retrieving Files"
    end
  end
end
