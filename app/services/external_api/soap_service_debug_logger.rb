# may be used with VBMS or VVA clients, pass instance to 'log' or 'logger' param (see client docs)

class SoapServiceDebugLogger
  def log(event, data)
    case event
    when :request
      puts "#{Time.zone.now} SOAP Request"
      pp data
    when :response
      puts "#{Time.zone.now} SOAP Response"
      pp data
    end
  end
end
