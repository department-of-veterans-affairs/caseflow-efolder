class ApplicationJob < ActiveJob::Base
  before_perform do |job|
    # setup debug context
    Raven.tags_context(job: job.class.name, queue: job.queue_name)
  end
end
