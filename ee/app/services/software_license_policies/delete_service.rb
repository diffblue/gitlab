# frozen_string_literal: true

module SoftwareLicensePolicies
  class DeleteService < ::BaseService
    def execute(software_license_policy)
      SoftwareLicensePolicy.transaction do
        software_license = SoftwareLicense.find(software_license_policy.software_license_id)

        software_license_policy.destroy!

        if software_license.spdx_identifier.nil? &&
            SoftwareLicensePolicy.count_for_software_license(software_license.id) == 0
          software_license.destroy!
        end
      end
    end
  end
end
