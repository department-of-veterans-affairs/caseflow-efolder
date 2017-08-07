require "#{Rails.root}/app/jobs/middleware/job_prometheus_metric_middleware"

Sidekiq.configure_server do |config|
  config.redis = { url: Rails.application.secrets.redis_url_sidekiq }

  schedule_file = Rails.root + "config/sidekiq_cron.yml"
  if File.exists?(schedule_file) && Sidekiq.server?
    Sidekiq::Cron::Job.load_from_hash! YAML.load_file(schedule_file)
  end

  config.server_middleware do |chain|
    chain.add JobPrometheusMetricMiddleware
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: Rails.application.secrets.redis_url_sidekiq }
end
