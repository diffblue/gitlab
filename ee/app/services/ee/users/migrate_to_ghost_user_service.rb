# frozen_string_literal: true

module EE
  module Users
    module MigrateToGhostUserService
      private

      def migrate_records
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
    end
  end
end
