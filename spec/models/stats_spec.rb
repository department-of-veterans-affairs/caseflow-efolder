describe Stats do
  before do
    Timecop.freeze(Time.utc(2016, 2, 17, 20, 59, 0))
    Rails.cache.clear
  end

  let(:monthly_stats) { Rails.cache.read("Stats-2016-2") }
  let(:weekly_stats) { Rails.cache.read("Stats-2016-w07") }
  let(:daily_stats) { Rails.cache.read("Stats-2016-2-17") }
  let(:hourly_stats) { Rails.cache.read("Stats-2016-2-17-15") }
  let(:prev_weekly_stats) { Rails.cache.read("Stats-2016-w06") }
  let(:user) { User.new(css_id: "ADA", station_id: "203") }

  context ".calculate_all!" do
    it "calculates and saves all calculated stats" do
      Download.create(status: :complete_success, completed_at: 40.days.ago, user: user)
      Download.create(status: :complete_success, completed_at: 7.days.ago, user: user)
      Download.create(status: :complete_success, completed_at: 2.days.ago, user: user)
      Download.create(status: :complete_success, completed_at: 4.hours.ago, user: user)
      Download.create(status: :complete_success, completed_at: 30.minutes.ago, user: user)

      Stats.calculate_all!

      expect(monthly_stats[:completed_download_count]).to eq(4)
      expect(weekly_stats[:completed_download_count]).to eq(3)
      expect(daily_stats[:completed_download_count]).to eq(2)
      expect(hourly_stats[:completed_download_count]).to eq(1)
      expect(prev_weekly_stats[:completed_download_count]).to eq(1)
    end

    it "overwrites incomplete periods" do
      Download.create(status: :complete_success, completed_at: 30.minutes.ago, user: user)
      Stats.calculate_all!
      Download.create(status: :complete_success, completed_at: 1.minute.ago, user: user)
      Stats.calculate_all!

      expect(hourly_stats[:completed_download_count]).to eq(2)
    end

    it "does not recalculate complete periods" do
      Download.create(status: :complete_success, completed_at: 7.days.ago, user: user)
      Stats.calculate_all!
      Download.create(status: :complete_success, completed_at: 7.days.ago, user: user)
      Stats.calculate_all!

      expect(prev_weekly_stats[:completed_download_count]).to eq(1)
    end
  end
end
