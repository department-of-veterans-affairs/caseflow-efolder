describe Calculator do
	context "#add" do
		context "when called with 1 and 2" do
			subject { Calculator.new.add(1, 2) }
			it { is_expected.to equal(3) }
		end
	end
end