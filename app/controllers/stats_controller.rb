class StatsController < ApplicationController
  before_action :authorize_system_admin

  def show
    @stats = Stats.new(
      time: Time.zone.now,
      interval: interval,
      past_period: 0
    )
  end

  private

  def interval
    Stats::INTERVALS.find { |i| i.to_s == params[:interval] } || :hourly
  end
end
