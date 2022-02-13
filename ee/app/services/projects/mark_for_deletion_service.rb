# frozen_string_literal: true

module Projects
  class MarkForDeletionService < BaseService
    def execute
      return success if project.marked_for_deletion_at?
      return error('Cannot mark project for deletion: feature not supported') unless can?(current_user, :delay_project_deletions)

      result = ::Projects::UpdateService.new(
        project,
        current_user,
        project_update_service_params
      ).execute
      log_event if result[:status] == :success
      log_error(result[:message]) if result[:status] == :error

      result
    end

    private

    def log_event
      log_audit_event
      log_info("User #{current_user.id} marked project #{project.full_path} for deletion")
    end

    def log_audit_event
      ::AuditEventService.new(
        current_user,
        project,
        action: :custom,
        custom_message: "Project marked for deletion"
      ).for_project.security_event
    end

    def project_update_service_params
      params = {
        archived: true,
        name: "#{project.name}-deleted-#{project.id}",
        path: "#{project.path}-deleted-#{project.id}",
        marked_for_deletion_at: Time.current.utc,
        deleting_user: current_user
      }
      params[:hidden] = true unless project.feature_available?(:adjourned_deletion_for_projects_and_groups)
      params
    end
  end
end
