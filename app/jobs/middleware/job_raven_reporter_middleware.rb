# This job captures all Shoryuken job exceptions and forwards them to Raven.
#
class JobRavenReporterMiddleware
  def call(_worker, queue, _msg, body)
    yield
  rescue StandardError => error
    tags = { job: body["job_class"], queue: queue }
    context = { message: body }
    Raven.capture_exception(error, tags: tags, extra: context) unless error.ignorable?
    raise
  end
end
