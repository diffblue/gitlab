# frozen_string_literal: true

class RepositoryPushAuditEventWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :authentication_and_authorization

  def perform(changes, project_id, user_id)
    project = Project.find(project_id)
    user = User.find(user_id)

    changes.map! do |change|
      before = change['before']
      after = change['after']
      ref = change['ref']

      service = AuditEvents::RepositoryPushAuditEventService
        .new(user, project, ref, before, after)
        .tap { |event| event.prepare_security_event }

      # Checking if it's enabled and reusing the changes array
      # is mostly a memory optimization.
      service if service.enabled?
    end.compact!

    AuditEvents::BulkInsertService.new(changes).execute
  end
end
