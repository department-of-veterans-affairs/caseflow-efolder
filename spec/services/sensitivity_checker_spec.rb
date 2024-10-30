# frozen_string_literal: true

describe SensitivityChecker do
  subject(:described) { described_class.new }

  let(:user) { User.create(css_id: "Foo", station_id: "112") }
  let(:mock_sensitivity_checker) { instance_double(BGSService) }

  before do
    allow(BGSService).to receive(:new).and_return(mock_sensitivity_checker)
  end

  describe "#sensitivity_levels_compatible?" do
    context "when the sensitivity levels are compatible" do
      it "returns true" do
        expect(mock_sensitivity_checker).to receive(:sensitivity_level_for_user)
          .with(user).and_return(Random.new.rand(4..9))
        expect(mock_sensitivity_checker).to receive(:sensitivity_level_for_veteran)
          .with("1234").and_return(Random.new.rand(1..4))

        expect(described.sensitivity_levels_compatible?(user: user, veteran_file_number: "1234")).to eq true
      end
    end

    context "when the sensitivity levels are NOT compatible" do
      it "returns false" do
        expect(mock_sensitivity_checker).to receive(:sensitivity_level_for_user)
          .with(user).and_return(Random.new.rand(1..4))
        expect(mock_sensitivity_checker).to receive(:sensitivity_level_for_veteran)
          .with("1234").and_return(Random.new.rand(4..9))

        expect(described.sensitivity_levels_compatible?(user: user, veteran_file_number: "1234")).to eq false
      end
    end

    context "when the BGS call raises an exception" do
      it "returns false" do
        error = StandardError.new

        expect(mock_sensitivity_checker).to receive(:sensitivity_level_for_user)
          .with(user).and_raise(error)
        expect(ExceptionLogger).to receive(:capture).with(error)

        expect(described.sensitivity_levels_compatible?(user: user, veteran_file_number: "1234")).to eq false
      end
    end
  end
end
