# frozen_string_literal: true

describe VeteranFinder do
  describe "#find" do
    let(:veteran_record) do
      {
        first_name: "Bob",
        last_name: "Marley",
        ssn: veteran_ssn,
        return_message: "hello world",
        claim_number: veteran_claim_number
      }
    end
    let(:veteran_claim_number) { "12345678" }
    let(:veteran_ssn) { "666001234" }
    let(:veteran_info) do
      {
        veteran_claim_number => veteran_record.merge(ptcpnt_id: "123", file_number: veteran_claim_number),
        veteran_ssn          => veteran_record.merge(ptcpnt_id: "456", file_number: veteran_ssn)
      }
    end

    let(:bgs) { Fakes::BGSService.new }
    let(:file_number) { veteran_ssn }

    subject { described_class.new(bgs: bgs).find(file_number) }

    before do
      allow(bgs).to receive(:veteran_info).and_return(veteran_info)
    end

    it "returns array of hashes of important veteran numbers" do
      expect(subject).to eq([
        {
          ssn: veteran_ssn,
          claim: veteran_claim_number,
          file: veteran_ssn,
          participant_id: "456",
          deceased: false,
          "file_number" => veteran_ssn,
          "veteran_first_name" => veteran_record[:first_name],
          "veteran_last_name"  => veteran_record[:last_name],
          "veteran_last_four_ssn" => veteran_ssn[-4..-1],
          "return_message" => veteran_record[:return_message]
        },
        {
          ssn: veteran_ssn,
          claim: veteran_claim_number,
          file: veteran_claim_number,
          participant_id: "123",
          deceased: false,
          "file_number" => veteran_claim_number,
          "veteran_first_name" => veteran_record[:first_name],
          "veteran_last_name"  => veteran_record[:last_name],
          "veteran_last_four_ssn" => veteran_ssn[-4..-1],
          "return_message" => veteran_record[:return_message]
        }
      ])
    end

    context "call with SSN" do
      let(:file_number) { veteran_ssn }

      it "returns SSN-as-file-number first" do
        expect(subject.first[:file]).to eq(veteran_ssn)
      end
    end

    context "call with claim number" do
      let(:file_number) { veteran_claim_number }

      it "returns claim-as-file-number first" do
        expect(subject.first[:file]).to eq(veteran_claim_number)
      end
    end

    context "no veteran found" do
      let(:veteran_info) { nil }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "BGS reports no :file_number" do
      let(:veteran_info) { { veteran_ssn => veteran_record.merge(ptcpnt_id: "123", file_number: "") } }

      it "uses claim_number" do
        expect(subject).to eq([
          {
            ssn: veteran_ssn,
            claim: veteran_claim_number,
            file: "",
            participant_id: "123",
            deceased: false,
            "file_number" => veteran_claim_number,
            "veteran_first_name" => veteran_record[:first_name],
            "veteran_last_name"  => veteran_record[:last_name],
            "veteran_last_four_ssn" => veteran_ssn[-4..-1],
            "return_message" => veteran_record[:return_message]
          }
        ])
      end
    end

    context "date of death defined" do
      let(:veteran_info) { { veteran_ssn => veteran_record.merge(ptcpnt_id: "123", date_of_death: "2020/03/29") } }

      it "sets deceased flag to true" do
        expect(subject).to eq([
          {
            ssn: veteran_ssn,
            claim: veteran_claim_number,
            file: nil,
            participant_id: "123",
            deceased: true,
            "file_number" => veteran_claim_number,
            "veteran_first_name" => veteran_record[:first_name],
            "veteran_last_name"  => veteran_record[:last_name],
            "veteran_last_four_ssn" => veteran_ssn[-4..-1],
            "return_message" => veteran_record[:return_message]
          }
        ])
      end
    end

    context "one veteran found" do
      let(:veteran_info) { { veteran_ssn => veteran_record.merge(ptcpnt_id: "123", file_number: veteran_ssn) } }

      it "returns array of one" do
        expect(subject.count).to eq(1)
        expect(subject).to eq([
          {
            ssn: veteran_ssn,
            claim: veteran_claim_number,
            file: veteran_ssn,
            participant_id: "123",
            deceased: false,
            "file_number" => veteran_ssn,
            "veteran_first_name" => veteran_record[:first_name],
            "veteran_last_name"  => veteran_record[:last_name],
            "veteran_last_four_ssn" => veteran_ssn[-4..-1],
            "return_message" => veteran_record[:return_message]
          }
        ])
      end
    end
  end
end
