# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require ::File.expand_path("../config/environment", __FILE__)
require "rack"
require "prometheus/middleware/collector"
require "prometheus/middleware/exporter"

require_relative "app/middleware/metrics_collector"

# require basic auth for the /metrics route
use MetricsAuth, "metrics" do |username, password|
  # if we mistakenly didn't set a password for this route, disable the route
  password_missing = ENV["METRICS_PASSWORD"].blank?
  password_matches = [username, password] == [ENV["METRICS_USERNAME"], ENV["METRICS_PASSWORD"]]
  password_missing ? false : password_matches
end

# use gzip for the '/metrics' route, since it can get big.
use Rack::Deflater,
    if: ->(env, _status, _headers, _body) { env["PATH_INFO"] == "/metrics" }

# Customized collector for our own metrics
use MetricsCollector

# Replace ids and id-like values to keep cardinality low.
# Otherwise Prometheus crashes on 400k+ data series.
# '/users/1234/comments' -> '/users/:id/comments'
# '/api/v2/records/7D11AE16-1DFF-49F5-AE31-B9E4675EBC30' -> '/api/v2/records/:id'
# rubocop:disable Style/StringLiterals
numeric_id_pattern = '\d+'
uuid_pattern = '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}'
# rubocop:enable Style/StringLiterals
# rubocop:disable Style/PercentLiteralDelimiters
id_matching_regex = %r'/(?:#{numeric_id_pattern}|#{uuid_pattern})(/|$)'
# rubocop:enable Style/PercentLiteralDelimiters

label_builder = lambda do |env, code|
  {
    code: code,
    method: env["REQUEST_METHOD"].downcase,
    host: env["HTTP_HOST"].to_s,
    path: env["PATH_INFO"].to_s.gsub(id_matching_regex, '/:id\\1')
  }
end

use Prometheus::Middleware::Collector,
    counter_label_builder: label_builder,
    duration_label_builder: label_builder

# exposes a metrics HTTP endpoint to be scraped by a prometheus server
use Prometheus::Middleware::Exporter

run Rails.application
