# frozen_string_literal: true

module EE
  module Issues
    module MoveService
      extend ::Gitlab::Utils::Override

      override :update_old_entity
      def update_old_entity
        rewrite_epic_issue
        rewrite_related_vulnerability_issues
        track_epic_issue_moved_from_project
        delete_pending_escalations
        super
      end

      private

      def rewrite_epic_issue
        return unless epic_issue = original_entity.epic_issue
        return unless can?(current_user, :update_epic, epic_issue.epic.group)

        return log_error_for(epic_issue) unless epic_issue.update(issue: new_entity)

        original_entity.reset

        ::Gitlab::UsageDataCounters::IssueActivityUniqueCounter.track_issue_changed_epic_action(author: current_user,
                                                                                                project: target_project)
      end

      def log_error_for(epic_issue)
        message = "Cannot create association with epic ID: #{epic_issue.epic.id}. " \
          "Error: #{epic_issue.errors.full_messages.to_sentence}"

        log_error(message)
      end

      def track_epic_issue_moved_from_project
        return unless original_entity.epic_issue

        ::Gitlab::UsageDataCounters::EpicActivityUniqueCounter.track_epic_issue_moved_from_project(
          author: current_user,
          namespace: original_entity.epic_issue.epic.group
        )
      end

      def rewrite_related_vulnerability_issues
        issue_links = Vulnerabilities::IssueLink.for_issue(original_entity)
        issue_links.update_all(issue_id: new_entity.id)
      end

      def delete_pending_escalations
        original_entity.pending_escalations.delete_all(:delete_all)
      end
    end
  end
end
