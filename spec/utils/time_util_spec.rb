describe TimeUtil do
  before { Timecop.freeze(Time.utc(2015, 1, 1, 12, 11, 37)) }
  after { Timecop.return }

  context "#floor" do
    it "works with seconds" do
      expect(TimeUtil.floor(30.seconds)).to eq(Time.utc(2015, 1, 1, 12, 11, 30))
    end

    it "works with minutes" do
      expect(TimeUtil.floor(30.minutes)).to eq(Time.utc(2015, 1, 1, 12, 0, 0))
    end
  end
end
