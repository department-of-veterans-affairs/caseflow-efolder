class JobSigtermMiddleware
  # When Shoryuken receives a call to shutdown (i.e. SIGTERM), it stops jobs that
  # are not complete. Since some of our jobs have long visibility timeouts they
  # may not be restarted for a long time. This gets around that problem by
  # forcing the visibility timeout on a job that did not complete to be 0, as is
  # suggested here: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html#terminating-message-visibility-timeout
  def call(_worker, _queue, msg, _body)
    job_finished = false
    yield
    # Note we only get to this point if the job was allowed to finish.
    job_finished = true
  ensure
    # Ensures always execute even on SIGTERMs (unless we cannot wrap up fast enough and are killed)
    msg.visibility_timeout = 30 if !job_finished
  end
end
