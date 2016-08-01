class CalculateStatsJob < ActiveJob::Base
  queue_as :default

  def perform(download)
    Stats.calculate_all!
  end

  def max_attempts
    1
  end
end
