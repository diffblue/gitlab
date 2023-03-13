# frozen_string_literal: true

module EpicIssues
  class CreateService < IssuableLinks::CreateService
    private

    # rubocop: disable CodeReuse/ActiveRecord
    def relate_issuables(referenced_issue)
      link = EpicIssue.find_or_initialize_by(issue: referenced_issue)

      params = { user_id: current_user.id }
      params[:original_epic_id] = link.epic_id if link.persisted?

      link.epic = issuable
      link.move_to_start

      link.run_after_commit do
        params.merge!(epic_id: link.epic.id, issue_id: referenced_issue.id)
        Epics::NewEpicIssueWorker.perform_async(params)
      end

      link.save

      ::GraphqlTriggers.issuable_epic_updated(referenced_issue)

      link
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def extractor_context
      { group: issuable.group }
    end

    def affected_epics(issues)
      [issuable, Epic.in_issues(issues)].flatten.uniq
    end

    def linkable_issuables(issues)
      @linkable_issues ||= begin
        return [] unless can?(current_user, :read_epic, issuable.group)

        Preloaders::UserMaxAccessLevelInProjectsPreloader
          .new(issues.map(&:project).compact, current_user)
          .execute

        issues.select do |issue|
          linkable_issue?(issue)
        end
      end
    end

    def linkable_issue?(issue)
      issue.supports_epic? &&
        can?(current_user, :admin_issue_relation, issue) &&
        !previous_related_issuables.include?(issue)
    end

    def previous_related_issuables
      @related_issues ||= issuable.issues.to_a
    end
  end
end
