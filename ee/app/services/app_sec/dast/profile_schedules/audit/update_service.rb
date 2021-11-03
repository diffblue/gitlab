# frozen_string_literal: true

module AppSec
  module Dast
    module ProfileSchedules
      module Audit
        class UpdateService < BaseProjectService
          def execute
            params[:new_params].each do |property, new_value|
              old_value = params[:old_params][property]

              next if old_value == new_value

              ::Gitlab::Audit::Auditor.audit(
                name: 'dast_profile_schedule_update',
                author: current_user,
                scope: project,
                target: params[:dast_profile_schedule],
                message: "Changed DAST profile schedule #{property} from #{old_value || 'nil'} to #{new_value}"
              )
            end
          end
        end
      end
    end
  end
end
