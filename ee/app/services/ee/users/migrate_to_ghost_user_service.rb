# frozen_string_literal: true

module EE
  module Users
    module MigrateToGhostUserService
      BATCH_SIZE = 1000

      private

      def migrate_records
        # these should always be ghosted
        migrate_resource_iteration_events

        return super if hard_delete

        migrate_epics
        migrate_vulnerabilities_feedback
        migrate_vulnerabilities
        migrate_vulnerabilities_external_issue_links
        migrate_vulnerabilities_state_transitions
        super
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def migrate_epics
        batched_migrate(::Epic, :author_id)
        batched_migrate(::Epic, :last_edited_by_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

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

      def migrate_vulnerabilities_state_transitions
        batched_migrate(Vulnerabilities::StateTransition, :author_id)
      end

      def migrate_resource_iteration_events
        batched_migrate(ResourceIterationEvent, :user_id)
      end
    end
  end
end
