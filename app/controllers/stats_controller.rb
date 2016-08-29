require 'json'

class StatsController < ApplicationController
  before_action :authorize_system_admin

  def show
    @stats = {
      hourly: 0..24,
      daily: 0..30,
      weekly: 0..26,
      monthly: 0..24
    }[interval].map { |i| Stats.offset(time: Time.zone.now, interval: interval, offset: i) }

    @json = @stats.map { |d| { key: d.range_start.to_f * 1000, value: d.values } }.to_json
  end

  private

  def interval
    Stats::INTERVALS.find { |i| i.to_s == params[:interval] } || :hourly
  end
end
