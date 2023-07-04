# frozen_string_literal: true

module EE
  module Users
    module MigrateRecordsToGhostUserService
      extend ::Gitlab::Utils::Override

      private

      override :migrate_records
      def migrate_records
        # these should always be ghosted
        migrate_resource_iteration_events
        migrate_resource_link_events

        return super if hard_delete

        migrate_epics
        migrate_vulnerabilities_feedback
        migrate_vulnerabilities
        migrate_vulnerabilities_external_issue_links
        super
      end

      override :post_migrate_records
      def post_migrate_records
        log_audit_event(user) if super.try(:destroyed?)
      end

      def migrate_epics
        batched_migrate(::Epic, :author_id)
        batched_migrate(::Epic, :last_edited_by_id)
      end

      def migrate_vulnerabilities_feedback
        batched_migrate(Vulnerabilities::Feedback, :author_id)
        batched_migrate(Vulnerabilities::Feedback, :comment_author_id)
      end

      def migrate_vulnerabilities
        batched_migrate(::Vulnerability, :author_id)
      end

      def migrate_vulnerabilities_external_issue_links
        batched_migrate(Vulnerabilities::ExternalIssueLink, :author_id)
      end

      def migrate_resource_iteration_events
        batched_migrate(ResourceIterationEvent, :user_id)
      end

      def migrate_resource_link_events
        batched_migrate(::WorkItems::ResourceLinkEvent, :user_id)
      end

      def log_audit_event(user)
        ::AuditEventService.new(
          initiator_user,
          user,
          action: :destroy
        ).for_user.security_event
      end
    end
  end
end
