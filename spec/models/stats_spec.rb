describe Stats do
  before do
    Timecop.freeze(Time.utc(2016, 2, 17, 15, 59, 0))
    Download.delete_all
    Rails.cache.clear
  end

  let(:monthly_stats) { Rails.cache.read("stats-2016-2") }
  let(:weekly_stats) { Rails.cache.read("stats-2016-w07") }
  let(:daily_stats) { Rails.cache.read("stats-2016-2-17") }
  let(:hourly_stats) { Rails.cache.read("stats-2016-2-17-15") }
  let(:prev_weekly_stats) { Rails.cache.read("stats-2016-w06") }

  context "#values" do
    let(:stats) { Stats.new(time: Time.zone.now, interval: "daily") }
    subject { stats.values }

    context "when cached stat values exist" do
      before do
        Rails.cache.write("stats-2016-2-17", completed_download_count: 44)
      end

      it "loads cached value" do
        expect(subject[:completed_download_count]).to eq(44)
      end
    end

    context "when no cached stat values exist" do
      before do
        Download.create(status: :complete_success, completed_at: 4.hours.ago)
      end

      it "calculates and caches values" do
        expect(subject[:completed_download_count]).to eq(1)
      end
    end
  end

  context ".calculate_all!" do
    it "calculates and saves all calculated stats" do
      Download.create(status: :complete_success, completed_at: 40.days.ago)
      Download.create(status: :complete_success, completed_at: 7.days.ago)
      Download.create(status: :complete_success, completed_at: 2.days.ago)
      Download.create(status: :complete_success, completed_at: 4.hours.ago)
      Download.create(status: :complete_success, completed_at: 30.minutes.ago)

      Stats.calculate_all!

      expect(monthly_stats[:completed_download_count]).to eq(4)
      expect(weekly_stats[:completed_download_count]).to eq(3)
      expect(daily_stats[:completed_download_count]).to eq(2)
      expect(hourly_stats[:completed_download_count]).to eq(1)
      expect(prev_weekly_stats[:completed_download_count]).to eq(1)
    end

    it "overwrites incomplete periods" do
      Download.create(status: :complete_success, completed_at: 30.minutes.ago)
      Stats.calculate_all!
      Download.create(status: :complete_success, completed_at: 1.minute.ago)
      Stats.calculate_all!

      expect(hourly_stats[:completed_download_count]).to eq(2)
    end

    it "does not recalculate complete periods" do
      Download.create(status: :complete_success, completed_at: 7.days.ago)
      Stats.calculate_all!
      Download.create(status: :complete_success, completed_at: 7.days.ago)
      Stats.calculate_all!

      expect(prev_weekly_stats[:completed_download_count]).to eq(1)
    end
  end

  context "#percentile" do
    class Thing
      include ActiveModel::Model
      attr_accessor :spiffyness
    end

    subject { Stats.percentile(:spiffyness, collection, 95) }

    context "with empty collection" do
      let(:collection) { [] }

      it { is_expected.to be_nil }
    end

    context "with nil values" do
      let(:collection) do
        [1, 45, nil, 2, 3, 4, 6, nil].map { |s| Thing.new(spiffyness: s) }
      end

      it { is_expected.to eq(45) }
    end

    context "with small collection" do
      let(:collection) do
        [1, 45, 2, 3, 4, 6].map { |s| Thing.new(spiffyness: s) }
      end

      it { is_expected.to eq(45) }
    end

    context "with large collection" do
      let(:collection) do
        (1..99).map { |s| Thing.new(spiffyness: s * 100) } + [Thing.new(spiffyness: 9501)]
      end

      it { is_expected.to eq(9501) }
    end
  end
end
