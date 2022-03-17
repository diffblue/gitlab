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
        migrate_requirements_management_requirements
        migrate_vulnerabilities_feedback
        super
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def migrate_epics
        batched_migrate(::Epic, :author_id)
        batched_migrate(::Epic, :last_edited_by_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def migrate_requirements_management_requirements
        user.requirements.update_all(author_id: ghost_user.id)
      end

      def migrate_vulnerabilities_feedback
        user.vulnerability_feedback.update_all(author_id: ghost_user.id)
        user.commented_vulnerability_feedback.update_all(comment_author_id: ghost_user.id)
      end

      def migrate_resource_iteration_events
        ResourceIterationEvent.by_user(user).each_batch(of: BATCH_SIZE) do |batch|
          batch.update_all(user_id: ghost_user.id)
        end
      end
    end
  end
end
