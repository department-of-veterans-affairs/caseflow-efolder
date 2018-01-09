##
# Stats is an interface to quickly access statistics for eFolder Express
# it is responsible for aggregating and caching statistics.
#
class Stats < Caseflow::Stats
  CALCULATIONS = {
    user_count: lambda do |range|
      Download.downloads_by_user(downloads: Download.where(completed_at: range)).count
    end,

    completed_download_count: lambda do |range|
      Download.where(completed_at: range).count
    end,

    document_count: lambda do |range|
      Document.where(completed_at: range, download_status: 1).count
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
end
