describe ExternalApi::BGSService do
  let(:bgs_service) { ExternalApi::BGSService.new }

  context "#parse_veteran_info" do
    before do
      @veteran_data = {
        ssn: "123-43-1111",
        first_name: "FirstName",
        last_name: "LastName"
      }
    end

    context "if bgs service returns a string ssn" do
      subject { bgs_service.parse_veteran_info(@veteran_data)["veteran_last_four_ssn"] }
      it { is_expected.to eq("1111") }
    end

    context "if bgs service returns no ssn in VetBirlsRecod, but it does in vetCorpRecord" do
      veteran_data = {
        ssn: nil,
        soc_sec_number: "43214321"
      }
      subject { bgs_service.parse_veteran_info(veteran_data)["veteran_last_four_ssn"] }
      it { is_expected.to eq("4321") }
    end

    context "if bgs service returns last name" do
      subject { bgs_service.parse_veteran_info(@veteran_data)["veteran_last_name"] }
      it { is_expected.to eq("LastName") }
    end

    context "if bgs service returns first name" do
      subject { bgs_service.parse_veteran_info(@veteran_data)["veteran_first_name"] }
      it { is_expected.to eq("FirstName") }
    end
  end

  context "#valid_file_number?" do
    subject { bgs_service.valid_file_number?(file_number) }

    context "when valid" do
      let(:file_number) { "123456789" }
      it { is_expected.to eq true }
    end

    context "when not a number" do
      let(:file_number) { "123K456789" }
      it { is_expected.to eq false }
    end

    context "when longer than 9 chars" do
      let(:file_number) { "1234567891" }
      it { is_expected.to eq false }
    end

    context "when shorter than 8 char" do
      let(:file_number) { "456789" }
      it { is_expected.to eq false }
    end
  end

  context "#record_found?" do
    subject { bgs_service.record_found?(veteran_info) }

    context "when found" do
      let(:veteran_info) { { "return_message" => "BPNQ0301" } }
      it { is_expected.to eq true }
    end

    context "when not found" do
      let(:veteran_info) { { "return_message" => "No BIRLS record found" } }
      it { is_expected.to eq false }
    end
  end
end
