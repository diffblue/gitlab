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
        super
      end

      private

      def rewrite_epic_issue
        return unless epic_issue = original_entity.epic_issue
        return unless can?(current_user, :update_epic, epic_issue.epic.group)
        return unless epic_and_issue_at_same_group_hierarchy?(new_entity, epic_issue.epic)

        updated = epic_issue.update(issue_id: new_entity.id)

        ::Gitlab::UsageDataCounters::IssueActivityUniqueCounter.track_issue_changed_epic_action(author: current_user) if updated

        original_entity.reset
      end

      def epic_and_issue_at_same_group_hierarchy?(new_issue, epic)
        temp_epic_issue = EpicIssue.new(issue_id: new_issue.id, epic_id: epic.id)

        temp_epic_issue.epic_and_issue_at_same_group_hierarchy?
      end

      def track_epic_issue_moved_from_project
        return unless original_entity.epic_issue

        ::Gitlab::UsageDataCounters::EpicActivityUniqueCounter.track_epic_issue_moved_from_project(author: current_user)
      end

      def rewrite_related_vulnerability_issues
        issue_links = Vulnerabilities::IssueLink.for_issue(original_entity)
        issue_links.update_all(issue_id: new_entity.id)
      end
    end
  end
end
