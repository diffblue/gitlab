# frozen_string_literal: true

module AuditEvents
  class UserImpersonationEventCreateWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :sticky
    feature_category :audit_events

    def perform(impersonator_id, user_id, remote_ip, action, created_at)
      ::AuditEvents::UserImpersonationGroupAuditEventService.new(
        impersonator: User.find_by_id(impersonator_id),
        user: User.find_by_id(user_id),
        remote_ip: remote_ip,
        action: action,
        created_at: created_at
      ).execute
    end
  end
end
