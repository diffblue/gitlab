# frozen_string_literal: true

# ProjectTemplateExportWorker is identical to ProjectExportWorker
# with the only exception of having higher urgency (low instead of throttled)
# and separate queue in order to allow users to create projects
# from custom templates faster, without getting stuck in the queue,
# since project_export queue can get congested by export requests
# which significantly delays project creation from custom templates.
class ProjectTemplateExportWorker < ProjectExportWorker # rubocop:disable Scalability/IdempotentWorker
  feature_category :importers
  loggable_arguments 2, 3
  sidekiq_options retry: false, dead: false
  sidekiq_options status_expiration: StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION
end
