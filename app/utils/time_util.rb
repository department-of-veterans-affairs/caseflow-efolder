# frozen_string_literal: true

module TimeUtil
  # Determines the closest increment of time to now
  # Eg: if you pass in 30 seconds, it will return the closest
  # whole 30 second increment before now
  # Time.floor(2016-10-17 15:48:17 -0400) => 2016-10-17 15:48:00 -0400
  def self.floor(increment)
    Time.zone.at((Time.now.to_f / increment).floor * increment)
  end
end
