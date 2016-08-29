##
# Stats is an interface to quickly access statistics for eFolder Express
# it is responsible for aggregating and caching statistics.
#
class Stats
  attr_accessor :interval, :time, :past_period, :values

  INTERVALS = [:hourly, :daily, :weekly, :monthly].freeze

  CALCULATIONS = {
    user_count: lambda do |range|
      Download.all_users(downloads: Download.where(completed_at: range)).count
    end,

    completed_download_count: lambda do |range|
      Download.where(completed_at: range).count
    end,

    document_count: lambda do |range|
      Download.document_count(downloads: Download.where(completed_at: range))
    end,

    time_to_fetch_manifest: lambda do |range|
      Stats.percentile(:time_to_fetch_manifest, Download.where(manifest_fetched_at: range), 95)
    end,

    time_to_fetch_files: lambda do |range|
      Stats.percentile(:time_to_fetch_files, Download.where(completed_at: range), 95)
    end,

    median_time_to_fetch_manifest: lambda do |range|
      Stats.percentile(:time_to_fetch_manifest, Download.where(manifest_fetched_at: range), 50)
    end,

    median_time_to_fetch_files: lambda do |range|
      Stats.percentile(:time_to_fetch_files, Download.where(completed_at: range), 50)
    end,

    searches_count: lambda do |range|
      Search.where(created_at: range).count
    end,

    complete_searches: lambda do |range|
      Search.where(status: [0, 1], created_at: range).count
    end,

    not_found_searches: lambda do |range|
      Search.veteran_not_found.where(created_at: range).count
    end,

    access_denied_searches: lambda do |range|
      Search.access_denied.where(created_at: range).count
    end,

    document_errors: lambda do |range|
      Document.failed.where(created_at: range).count
    end,

    top_users: lambda do |range|
      Download.top_users(downloads: Download.where(completed_at: range))
    end
  }.freeze

  def initialize(interval:, time:, past_period:)
    self.interval = interval.to_sym
    self.time = time
    self.past_period = past_period
  end

  def values
    @values ||= load_values || calculate_and_save_values!
  end

  def complete?
    values = load_values
    values && values[:complete]
  end

  def calculate_and_save_values!
    return true if complete?
    calculated_values = calculate_values
    calculated_values[:complete] = time >= range_finish
    Rails.cache.write(cache_id, calculated_values)
    calculated_values
  end

  def self.calculate_all!
    INTERVALS.each do |interval|
      {
        hourly: 0..24,
        daily: 0..30,
        weekly: 0..26,
        monthly: 0..24
      }[interval].each do |past_period|
        Stats.new(interval: interval, time: Time.zone.now, past_period: past_period)
             .calculate_and_save_values!
      end
    end
  end

  def self.percentile(attribute, collection, percentile)
    return nil if collection.empty?

    filtered = collection.reject { |model| model.send(attribute).nil? }
    sorted = filtered.sort_by(&attribute)
    percentile_model = sorted[((sorted.size - 1) * (percentile / 100.0)).ceil]
    percentile_model && percentile_model.send(attribute)
  end

  private

  def load_values
    Rails.cache.read(cache_id)
  end

  def calculate_values
    CALCULATIONS.each_with_object({}) do |(key, calculation), result|
      result[key] = calculation.call(range)
    end
  end

  def cache_id
    @id ||= calculate_cache_id
  end

  def calculate_cache_id
    id = "stats-#{range_start.year}"

    case interval
    when :monthly then id + "-#{range_start.month}"
    when :weekly  then id + "-w#{range_start.strftime('%U')}"
    when :daily   then id + "-#{range_start.month}-#{range_start.day}"
    when :hourly  then id + "-#{range_start.month}-#{range_start.day}-#{range_start.hour}"
    end
  end

  def range
    range_start..range_finish
  end

  def range_start
    @range_start ||= {
      hourly: time.beginning_of_hour - past_period.hours,
      daily: time.beginning_of_day - past_period.days,
      weekly: time.beginning_of_week - past_period.weeks,
      monthly: time.beginning_of_month - past_period.months
    }[interval]
  end

  def range_finish
    @range_finish ||= {
      hourly: range_start + 1.hour,
      daily: range_start + 1.day,
      weekly: range_start + 1.week,
      monthly: range_start.next_month
    }[interval]
  end
end
