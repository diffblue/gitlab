# frozen_string_literal: true

# Managed license creation service. For use in the managed license controller.
module SoftwareLicensePolicies
  class CreateService < ::BaseService
    def initialize(project, user, params)
      super(project, user, params.with_indifferent_access)
    end

    def execute
      return error("", 403) unless can?(@current_user, :admin_software_license_policy, @project)

      success(software_license_policy: create_software_license_policy)
    rescue ActiveRecord::RecordInvalid => exception
      error(exception.record.errors.full_messages, 400)
    rescue ArgumentError => exception
      log_error(exception.message)
      error(exception.message, 400)
    end

    private

    def create_software_license_policy
      policy = SoftwareLicense.create_policy_for!(
        project: project,
        name: params[:name],
        classification: params[:approval_status]
      )
      RefreshLicenseComplianceChecksWorker.perform_async(project.id)
      policy
    end
  end
end
