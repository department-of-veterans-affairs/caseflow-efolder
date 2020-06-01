require "rails_helper"

RSpec.feature "User Error Flows" do
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

  let(:invalid_veteran_id) { "abcd" }

  let(:veteran_id) { "12341234" }
  let(:veteran_info) do
    {
      "file_number" => veteran_id,
      "veteran_first_name" => "Stan",
      "veteran_last_name" => "Lee",
      "veteran_last_four_ssn" => "2222",
      "return_message" => "BPNQ0301"
    }
  end

  before do
    @user = User.create(css_id: "123123", station_id: "116")

    User.authenticate!

    allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info).and_return(veteran_info)
    allow_any_instance_of(Fakes::BGSService).to receive(:valid_file_number?).with(veteran_id).and_return(true)
    allow_any_instance_of(Fakes::BGSService).to receive(:valid_file_number?).with(invalid_veteran_id).and_return(false)

    allow(Fakes::VBMSService).to receive(:v2_fetch_documents_for).and_return(documents)
    allow(Fakes::VVAService).to receive(:v2_fetch_documents_for).and_return([])
    allow(Fakes::DocumentService).to receive(:v2_fetch_document_file).and_return("Test content")

    S3Service.files = {}

    allow(S3Service).to receive(:stream_content).and_return("streamed content")

    DownloadHelpers.clear_downloads
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
    let(:veteran_info) do
      {
        "file_number" => nil,
        "veteran_first_name" => nil,
        "veteran_last_name" => nil,
        "veteran_last_four_ssn" => nil,
        "return_message" => "No BIRLS record found"
      }
    end
    before do
      allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info).and_return(veteran_info)
    end

    scenario "Requesting veteran_id returns cannot find eFolder" do
      visit "/"
      fill_in "Search for a Veteran ID number below to get started.", with: veteran_id

      click_button "Search"
      expect(page).to have_content("could not find an eFolder with the Veteran ID")
    end
  end

  context "When veteran id has high sensitivity" do
    scenario "Cannot access it" do
      allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info).and_raise("Sensitive File - Access Violation")
      visit "/"
      fill_in "Search for a Veteran ID number below to get started.", with: veteran_id
      click_button "Search"

      expect(page).to have_content("This efolder contains sensitive information")
    end

    scenario "VSO cannot access it" do
      allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info)
        .and_raise("Power of Attorney of Folder is '071'. Access to this record is denied.")
      visit "/"
      fill_in "Search for a Veteran ID number below to get started.", with: veteran_id
      click_button "Search"

      expect(page).to have_content("This efolder belongs to a Veteran you do not represent")
    end
  end

  context "UserAuthorizer" do
    let(:veteran_participant_id) { "123" }
    let(:poa_participant_id) { "345" }

    let(:bgs_claimants_poa_fn_response) do
      {
        person_org_name: "A Lawyer",
        person_org_ptcpnt_id: poa_participant_id,
        person_organization_name: "POA Attorney",
        relationship_name: "Power of Attorney For",
        veteran_ptcpnt_id: veteran_participant_id
      }
    end

    before do
      allow_any_instance_of(BGSService).to receive(:fetch_poa_by_file_number)
        .with(veteran_id) { bgs_claimants_poa_fn_response }
    end

    context "When veteran_id has no veteran info" do
      let(:veteran_info) do
        {
          "file_number" => nil,
          "veteran_first_name" => nil,
          "veteran_last_name" => nil,
          "veteran_last_four_ssn" => nil,
          "return_message" => "No BIRLS record found"
        }
      end
      before do
        allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info).and_return(veteran_info)
      end

      scenario "Requesting veteran_id returns cannot find eFolder" do
        visit "/"
        fill_in "Search for a Veteran ID number below to get started.", with: veteran_id

        click_button "Search"
        expect(page).to have_content("could not find an eFolder with the Veteran ID")
      end
    end

    context "When veteran id has high sensitivity" do
      scenario "Cannot access it" do
        allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info)
          .and_raise(StandardError.new("Sensitive File - Access Violation"))
        visit "/"
        fill_in "Search for a Veteran ID number below to get started.", with: veteran_id
        click_button "Search"

        expect(page).to have_content("This efolder contains sensitive information")
      end

      let(:bgs_claimants_poa_fn_response) { nil }

      scenario "VSO cannot access it" do
        allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info) do |bgs|
         if bgs.client.css_id == User.system_user.css_id
            veteran_info
          else
            raise BGS::ShareError.new("Power of Attorney of Folder is '071'. Access to this record is denied.")
          end
        end
        visit "/"
        fill_in "Search for a Veteran ID number below to get started.", with: veteran_id
        click_button "Search"

        expect(page).to have_content("This efolder belongs to a Veteran you do not represent")
      end
    end
  end

  context "When veteran case folder has no documents" do
    before do
      allow(Fakes::VBMSService).to receive(:v2_fetch_documents_for).and_return([])
      allow(Fakes::VVAService).to receive(:v2_fetch_documents_for).and_return([])
      allow_any_instance_of(Fakes::BGSService).to receive(:record_found?).with(veteran_info).and_return(true)
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
