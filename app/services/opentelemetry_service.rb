require 'opentelemetry'

# Initialize OpenTelemetry
OpenTelemetry::SDK.configure do |c|
    c.use 'OpenTelemetry::Instrumentation::Rack'
    c.use 'OpenTelemetry::Instrumentation::MyCustomInstrumentation'
    c.use 'OpenTelemetry::Exporter'
    c.use 'OpenTelemetry::Instrumentation::MyOtherInstrumentation'
end

#OR
=begin
require 'opentelemetry'
OpenTelemetry:SDK.configure do |c|
    c.use_all
    c.use 'OpenTelemetry::Exporters::MyExporter'
end
=end

class OpenTelemetryService

    def initialize
        @host = `curl http://instance-data/latest/meta-data/instance-id --silent || echo "not-ec2"`.strip
        #meter? @tracer = OpenTelemetry.tracer.provider.tracer('OpenTelemetryService', '0.1')
    end

    def increment_counter(metric_group:, metric_name:, app_name:, attrs: {})
        tags = attributes_to_tags(app_name, attrs)
        stat_name = get_stat_name(metric_group, metric_name)

        @tracer.in_span('increment_counter') do |span|
            meter.set_attribute('stat_name', stat_name)
            span.set_attribute('tags', tags)
        end
    end

    def emit_gauge(metric_group:, metric_name:, metric_value:, app_name:, attrs:{})
        tags = attributes_to_tags(app_name, attrs)
        stat_name = get_stat_name(metric_group, metric_name)

        @tracer.in_span('emit_gauge') do |span|
            span.set_attribute('stat_name', stat_name)
            span.set_attribute('tags', tags)
        end
    end

    private

    def get_stat_name(metric_group, metric_name)
        "dsva-appeals.#{metric_group}.#{metric_name}"
    end

    def attributes_to_tags(app_name, attrs)
        extra_tags = attrs.map { |key, val| "#{key}:#{val}" }
        [
            "app:#{app_name}",
            "env:#{Rails.current_env}",
            "hostname:#{@host}"
        ] + extra_tags
    end
end

=begin
class OpenTelemetryService
    def initialize
        @meter = OpenTelemetry.meter
    end

    def increment_counter(metric_group:, metric_name:, app_name:, attrs: {})
        tags = attributes_to_tags(app_name, attrs)
        stat_name = get_stat_name(metric_group, metric_name)

        counter = @meter.create_integer_counter(
            name: stat_name,
            description: 'Description of the counter metric',
            unit: '1',
            labels: tags.keys
        )

        counter.add(1, labels: tags)
    end

    def emit_gauge(metric_group:, metric_name:, metric_value:, app_name:, attrs: {})
        tags = attributes_to_tags(app_name, attrs)
        stat_name = get_stat_name(metric_group, metric_name)

        gauge = @meter.create_double_gauge(
            name: stat_name,
            description: 'Description of the gauge metric',
            unit: '1',
            labels: tags.keys
        )

        gauge.set(metric_value, labels: tags)
    end

    private

    def get_stat_name(metric_group, metric_name)
        "dsva-appeals.#{metric_group}.#{metric_name}"
    end

    def attributes_to_tags(app_name, attrs)
        extra_tags = attrs.map { |key, val| "#{key}:{val}" }
        [
            "app:#{app_name}",
            "env:#{Rails.current_env}",
            "hostname:#{@host}"
        ] + extra_tags
    end
end
=end


    
