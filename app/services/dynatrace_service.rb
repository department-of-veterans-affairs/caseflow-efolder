# frozen_string_literal: true

class ExternalApi::DynatraceService

    BASE_URL = ENV["TBD"]
    SSL_CERT_FILE = ENV["SSL_CERT_FILE"]
  
    class << self
  
    def  increment(stat_name, tags: tags, by: by)
      #stuff
      # build request
      request = HTTPI::Request.new(BASE_URL)
      request.open_timeout = 300
      request.read_timeout = 300
      request.auth.ssl.ca_cert_file = ENV["SSL_CERT_FILE"]
  
      # build body
      request.body = render json: {
        displayName: stat_name,
        description: "",
        unit: "Unspecified",
        tags: tags,
        }
  
      HTTPI.post(request)
    end
  
    def gauge(stat_name, metric_value, tags: tags)
      #stuff
      # build request
      request = HTTPI::Request.new(BASE_URL)
      request.open_timeout = 300
      request.read_timeout = 300
      request.auth.ssl.ca_cert_file = ENV["SSL_CERT_FILE"]
  
      # build body
      request.body = render json: {
        displayName: stat_name,
        description: "",
        unit: "Unspecified",
        tags: tags,
        }
  
      HTTPI.post(request)
    end
  
  
  # TODO  exception handleing
  # Response codes
  # Code	Type	Description
  # 202	ValidationResponse
  # The provided metric data points are accepted and will be processed in the background.
  
  # 400	ValidationResponse
  # Some data points are invalid. Valid data points are accepted and will be processed in the background.
  
=begin
Example JSON
{
  "displayName": "Total revenue",
  "description": "Total store revenue by region, city, and store",
  "unit": "Unspecified",
  "tags": ["KPI", "Business"],
  "metricProperties": {
    "maxValue": 1000000,
    "minValue": 0,
    "rootCauseRelevant": false,
    "impactRelevant": true,
    "valueType": "score",
    "latency": 1
  },
  "dimensions": [
    {
      "key": "city",
      "displayName": "City name"
    },
    {
      "key": "country",
      "displayName": "Country name"
    },
    {
      "key": "region",
      "displayName": "Sales region"
    },
    {
      "key": "store",
      "displayName": "Store #"
    }
  ]
}
=end
