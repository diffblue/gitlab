# frozen_string_literal: true

# Epics::TransferService class
#
# Used for recreating the missing epics when transferring a project to a new group
#
module Epics
  class TransferService
    attr_reader :current_user, :old_group, :project

    def initialize(current_user, old_group, project)
      @current_user = current_user
      @old_group = old_group
      @project = project
    end

    def execute
      return unless old_group.present? && project.group.present?
      # If the old group is an ancestor of the new group the epic can remain assigned
      return if project.group.ancestors.include?(old_group)

      Epic.transaction do
        epics_to_transfer.find_each do |epic|
          new_epic = create_epic(epic)

          update_issues_epic(epic, new_epic)
        end
      end
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def epics_to_transfer
      Epic.joins(:issues)
        .where(
          issues: { project_id: project.id },
          group_id: old_group.self_and_descendants
        ).distinct
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def create_epic(epic)
      return unless current_user.can?(:create_epic, project.group)

      epic_params = epic.attributes
                        .slice('title', 'description', 'start_date', 'end_date', 'confidential')

      CreateService.new(
        group: project.group,
        current_user: current_user,
        params: epic_params).execute_without_rate_limiting
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def update_issues_epic(old_epic, new_epic)
      issues = old_epic.issues.where(project: project)

      issues.each do |issue|
        if new_epic.present?
          create_epic_issue_link(issue, new_epic)
        else
          destroy_epic_issue_link(issue, old_epic)
        end
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def create_epic_issue_link(issue, epic)
      link_params = { target_issuable: issue, skip_epic_dates_update: true }

      EpicIssues::CreateService.new(epic, current_user, link_params).execute
    end

    def destroy_epic_issue_link(issue, epic)
      link = EpicIssue.find_by_issue_id(issue.id)

      EpicIssues::DestroyService.new(link, current_user).execute
    end
  end
end
