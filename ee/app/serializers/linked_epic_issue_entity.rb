# frozen_string_literal: true

class LinkedEpicIssueEntity < LinkedIssueEntity
  include RequestAwareEntity

  expose :relation_path, override: true do |issue|
    if can_admin_issue_link?(issue)
      group_epic_issue_path(issuable.group, issuable.iid, issue.epic_issue_id)
    end
  end

  expose :reference, override: true do |issue|
    issue.to_reference(full: true)
  end

  expose :epic_issue_id

  with_options if: -> (_, options) { options[:blocked_issues_ids] } do
    expose :blocked do |issue, options|
      options[:blocked_issues_ids].include?(issue.id)
    end
  end

  private

  def can_admin_issue_link?(issue)
    Ability.allowed?(current_user, :admin_issue_relation, issue) &&
      Ability.allowed?(current_user, :admin_epic_relation, issuable)
  end
end
