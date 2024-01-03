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

# frozen_string_literal: true

require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/all'

DT_API_URL = ''
DT_API_TOKEN = ''

def init_opentelemetry
  OpenTelemetry::SDK.configure do |c|
    c.service_name = 'ruby-quickstart' #TODO Replace with the name of your application
    c.service_version = '1.0.1' #TODO Replace with the version of your application
    for name in ["dt_metadata_e617c525669e072eebe3d0f08212e8f2.properties", "/var/lib/dynatrace/enrichment/dt_metadata.properties"] do
      begin
        # Resource configuration
        c.resource = OpenTelemetry::SDK::Resources::Resource.create({
        OpenTelemetry::SemanticConventions::Resource::SERVICE_NAMESPACE => 'eFolder Express',
        OpenTelemetry::SemanticConventions::Resource::SERVICE_NAME => 'rails',
        OpenTelemetry::SemanticConventions::Resource::SERVICE_INSTANCE_ID => Socket.gethostname,
        OpenTelemetry::SemanticConventions::Resource::SERVICE_VERSION => "0.0.0"
        })      rescue
    c.use_all
      end
    end
    c.add_span_processor(
      OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
        OpenTelemetry::Exporter::OTLP::Exporter.new(
          endpoint: DT_API_URL + "/v1/traces",
          headers: {
            "Authorization": "Api-Token " + DT_API_TOKEN
          }
        )
      )
    )
  end
end
