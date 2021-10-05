# frozen_string_literal: true

module RequirementsManagement
  class UpdateRequirementService < BaseService
    def execute(requirement)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :update_requirement, project)

      attrs = allowlisted_requirement_params

      requirement.assign_attributes(attrs)

      # This is part of the migration from Requirement (the first class object)
      # to Issue/Work Item (of type Requirement).
      # We can't wrap the change in a Transaction (see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/64929#note_647123684)
      # so we'll check if both are valid before saving
      if requirement.valid? && requirement.requirement_issue
        updated_issue = sync_with_requirement_issue(requirement)

        if updated_issue&.invalid?
          requirement.requirement_issue_sync_error!
          ::Gitlab::AppLogger.info(message: "Requirement-Issue Sync: Associated issue could not be saved", project_id: project.id, user_id: current_user.id, params: params)
        end
      end

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

      TestReport.build_report(requirement: requirement, state: params[:last_test_report_state], author: current_user).save!
    end

    def allowlisted_requirement_params
      params.slice(:title, :description, :state)
    end

    def sync_with_requirement_issue(requirement)
      sync_params = RequirementsManagement::Requirement.sync_params
      changed_attrs = requirement.changed.map(&:to_sym) & sync_params

      return unless changed_attrs.any?

      sync_attrs = requirement.attributes.with_indifferent_access.slice(*changed_attrs)

      requirement_issue = requirement.requirement_issue

      state_change = sync_attrs.delete(:state)
      update_requirement_issue_title_and_description(requirement_issue, sync_attrs)
      update_requirement_issue_state(requirement_issue, state_change)
    end

    def update_requirement_issue_title_and_description(requirement_issue, params)
      return requirement_issue unless params.any?

      title_and_description = params.with_indifferent_access.slice(:title, :description)

      ::Issues::UpdateService.new(project: project, current_user: current_user, params: title_and_description)
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
