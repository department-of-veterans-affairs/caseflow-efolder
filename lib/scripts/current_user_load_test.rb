class CurrentUserLoadTests
  def initialize(iterations = 100)
    @iterations = iterations
  end

  # This attempts to mimic a user that has many open browser tabs while accessing eFolder
  def run
    successful_fork = 0
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    puts "Starting run with #{@iterations} iterations"

    @iterations.times do
      fork { User.from_session_and_request(session, request) }
      successful_fork += 1
    end

    Process.waitall
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    elasped_time = end_time - start_time

    puts "Completed run successfully \n Elasped Time: #{elasped_time} seconds \n Successful Forks: #{successful_fork}"
  end

  def request
    OpenStruct.new(remote_ip: "123.123.222.222")
  end

  def session
    {
      "user" => {
        "css_id" => "auser",
        "email" => "email@va.gov",
        "station_id" => "213",
        "roles" => ["Download eFolder"],
        "name" => "Manny Requests",
        "ip_address" => "12.12.12.12"
      }
    }
  end
end
