##We may need to add an OTEL initializer. 
# config/initializers/opentelemetry.rb
#require 'opentelemetry/sdk'
#require 'opentelemetry/instrumentation/all'
#require 'opentelemetry-exporter-otlp'
#OpenTelemetry::SDK.configure do |c|
#  c.service_name = 'dice-ruby'
#  c.use_all() # enables all instrumentation!
#end
#https://opentelemetry.io/docs/instrumentation/ruby/exporters/