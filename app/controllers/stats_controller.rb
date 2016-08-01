class StatsController < ApplicationController
  skip_before_action :authenticate
  skip_before_action :authorize

  def show
    @stats = Stats.new(
      time: Time.zone.now,
      interval: interval
    )
  end

  private

  def interval
    Stats::INTERVALS.find { |i| i.to_s == params[:interval] } || :hourly
  end
end
