# frozen_string_literal: true

module RequirementsManagement
  class UpdateRequirementService < BaseService
    def execute(requirement)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :update_requirement, project)

      attrs = whitelisted_requirement_params

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

    def whitelisted_requirement_params
      params.slice(:title, :description, :state)
    end

    def sync_with_requirement_issue(requirement)
      sync_params = RequirementsManagement::Requirement.sync_params
      changed_attrs = requirement.changed.map(&:to_sym) & sync_params

      return unless changed_attrs.any?

      sync_attrs = requirement.attributes.with_indifferent_access.slice(*changed_attrs)

      requirement_issue = requirement.requirement_issue

      # Skip authorisation so we don't risk a permissions mismatch while still getting the advantages
      # of the service, such as system notes.
      params = sync_attrs.merge(skip_auth: true)
      ::Issues::UpdateService.new(project: project, current_user: current_user, params: params)
        .execute(requirement_issue)
    end
  end
end
