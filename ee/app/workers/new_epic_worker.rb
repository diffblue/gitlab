# frozen_string_literal: true

class NewEpicWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include NewIssuable

  feature_category :portfolio_management
  worker_resource_boundary :cpu
  weight 2

  def perform(epic_id, user_id)
    return unless objects_found?(epic_id, user_id)

    EventCreateService.new.open_epic(issuable, user)
    NotificationService.new.new_epic(issuable, user)
    issuable.create_cross_references!(user)
    log_audit_event if user.project_bot?
  end

  def issuable_class
    Epic
  end

  private

  def log_audit_event
    audit_context = {
      name: "epic_created_by_project_bot",
      author: user,
      scope: issuable.group,
      target: issuable,
      message: "Created epic #{issuable.title}",
      target_details: { iid: issuable.iid, id: issuable.id }
    }

    ::Gitlab::Audit::Auditor.audit(audit_context)
  end
end
