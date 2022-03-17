# frozen_string_literal: true

module RequirementsManagement
  class UpdateRequirementService < BaseService
    include SyncWithRequirementIssue

    def execute(requirement)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :update_requirement, project)

      attrs = allowlisted_requirement_params

      requirement.assign_attributes(attrs)

      sync_issue_for(requirement)

      requirement.save
      create_test_report_for(requirement) if manually_create_test_report?

      requirement
    end

    private

    def manually_create_test_report?
      params[:last_test_report_state].present?
    end

    def create_test_report_for(requirement)
      return unless can?(current_user, :create_requirement_test_report, project)

      TestReport.build_report(requirement_issue: requirement.requirement_issue, state: params[:last_test_report_state], author: current_user).save!
    end

    def allowlisted_requirement_params
      params.slice(:title, :description, :state)
    end

    def perform_sync(requirement, attributes)
      requirement_issue = requirement.requirement_issue

      state_change = attributes.delete(:state)
      update_requirement_issue_state(requirement_issue, state_change)

      ::Issues::UpdateService.new(project: project, current_user: current_user, params: attributes)
        .execute(requirement_issue)
    end

    def update_requirement_issue_state(requirement_issue, new_state)
      return requirement_issue unless new_state

      service =
        if new_state.to_sym == :opened
          ::Issues::ReopenService
        else
          ::Issues::CloseService
        end

      service.new(project: project, current_user: current_user).execute(requirement_issue, skip_authorization: true)
    end
  end
end
