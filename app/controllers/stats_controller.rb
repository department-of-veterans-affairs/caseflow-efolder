# frozen_string_literal: true

require "json"

class StatsController < ApplicationController
  before_action :authorize_system_admin

  def show
    @stats = {
      hourly: 0...24,
      daily: 0...30,
      weekly: 0...26,
      monthly: 0...24
    }[interval].map { |i| Stats.offset(time: Stats.now, interval: interval, offset: i) }
  end

  private

  def json
    @stats.map { |d| { key: d.range_start.to_f, value: d.values } }.to_json
  end
  helper_method :json

  def interval
    @interval ||= Stats::INTERVALS.find { |i| i.to_s == params[:interval] } || :hourly
  end
  helper_method :interval
end
