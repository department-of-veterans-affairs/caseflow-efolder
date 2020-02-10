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

    subject { described_class.new(bgs: bgs).find(veteran_ssn) }

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
          "file_number" => veteran_claim_number,
          "veteran_first_name" => veteran_record[:first_name],
          "veteran_last_name"  => veteran_record[:last_name],
          "veteran_last_four_ssn" => veteran_ssn[-4..-1],
          "return_message" => veteran_record[:return_message]
        }
      ])
    end
  end
end
