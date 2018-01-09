require "rails_helper"

describe Veteran do
  let(:veteran) { Veteran.new(file_number: "445566") }

  context "#load_bgs_record!" do
    subject { veteran.load_bgs_record! }

    let(:veteran_record) do
      {
        "veteran_first_name" => "June",
        "veteran_last_name" => "Juniper",
        "veteran_last_four_ssn" => "6789"
      }
    end

    before do
      allow_any_instance_of(Fakes::BGSService).to receive(:veteran_info).and_return("445566" => veteran_record)
    end

    context "when veteran does not exist in BGS" do
      before do
        veteran.file_number = "DOESNOTEXIST"
      end

      it { is_expected.to_not be_found }
    end

    context "when veteran has no BIRLS record", pending: true do
      let(:veteran_record) do
        { file_number: nil }
      end

      it { is_expected.to_not be_found }
    end

    it "returns the veteran with data loaded from BGS" do
      is_expected.to have_attributes(
        file_number: "445566",
        first_name: "June",
        last_name: "Juniper",
        last_four_ssn: "6789"
      )
    end
  end
end
