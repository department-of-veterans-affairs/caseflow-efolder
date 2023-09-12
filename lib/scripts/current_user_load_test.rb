class CurrentUserLoadTest

  def initialize(iterations = 100)
    @iterations = iterations
  end

  def run
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    puts "Starting run with #{@iterations} iterations"

    @iterations.times do |i|
      # call current_user here
    end

    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    elasped_time = end_time - start_time

    puts "Completed run successfully \b Elasped Time: #{elasped_time} seconds"
  end
end