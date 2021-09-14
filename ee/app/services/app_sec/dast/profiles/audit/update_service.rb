# frozen_string_literal: true

module AppSec
  module Dast
    module Profiles
      module Audit
        class UpdateService < BaseContainerService
          def execute
            params[:new_params].each do |property, new_value|
              old_value = params[:old_params][property]

              next if old_value.to_s == new_value.to_s

              ::Gitlab::Audit::Auditor.audit(
                name: 'dast_profile_update',
                author: current_user,
                scope: container,
                target: params[:dast_profile],
                message: audit_message(property, new_value, old_value)
              )
            end
          end

          private

          def audit_message(property, new_value, old_value)
            case property
            when :dast_scanner_profile_id
              old_value, new_value = DastScannerProfile.names([old_value, new_value])
              property = :dast_scanner_profile
            when :dast_site_profile_id
              old_value, new_value = DastSiteProfile.names([old_value, new_value])
              property = :dast_site_profile
            end

            "Changed DAST profile #{property} from #{old_value} to #{new_value}"
          end
        end
      end
    end
  end
end
