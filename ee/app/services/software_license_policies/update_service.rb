# frozen_string_literal: true

# Managed license update service. For use in the managed license controller.
module SoftwareLicensePolicies
  class UpdateService < ::BaseService
    def initialize(project, user, params)
      super(project, user, params.with_indifferent_access)
    end

    def execute(software_license_policy)
      return error("", 403) unless can?(@current_user, :admin_software_license_policy, @project)
      return success(software_license_policy: software_license_policy) unless params[:approval_status].present?

      software_license_policy.update(classification: params[:approval_status])

      success(software_license_policy: software_license_policy)
    rescue ArgumentError => ex
      error(ex.message, 400)
    end
  end
end
