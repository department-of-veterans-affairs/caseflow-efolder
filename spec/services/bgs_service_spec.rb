describe ExternalApi::BGSService do
  let(:bgs_service) { ExternalApi::BGSService.new }

  context "#parse_veteran_info" do
    before do
      @veteran_info = {
        ssn_nbr: "123-43-1111",
        first_nm: "FirstName",
        last_nm: "LastName"
      }
    end

    context "if bgs service returns a string ssn" do
      subject { bgs_service.parse_veteran_info(@veteran_info)["veteran_last_four_ssn"] }
      it { is_expected.to eq("1111") }
    end

    context "if bgs service returns no ssn" do
      veteran_info = {
        ssn_nbr: nil
      }
      subject { bgs_service.parse_veteran_info(veteran_info)["veteran_last_four_ssn"] }
      it { is_expected.to eq(nil) }
    end

    context "if bgs service returns last name" do
      subject { bgs_service.parse_veteran_info(@veteran_info)["veteran_last_name"] }
      it { is_expected.to eq("LastName") }
    end

    context "if bgs service returns first name" do
      subject { bgs_service.parse_veteran_info(@veteran_info)["veteran_first_name"] }
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

    context "when shorter than 8 char" do
      let(:file_number) { "456789" }
      it { is_expected.to eq false }
    end
  end
end
