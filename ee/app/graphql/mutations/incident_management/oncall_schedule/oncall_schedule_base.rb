# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module OncallSchedule
      class OncallScheduleBase < BaseMutation
        field :oncall_schedule,
              ::Types::IncidentManagement::OncallScheduleType,
              null: true,
              description: 'On-call schedule.'

        authorize :admin_incident_management_oncall_schedule

        private

        def response(result)
          {
            oncall_schedule: result.payload[:oncall_schedule],
            errors: result.errors
          }
        end

        def find_object(project_path:, **args)
          project = Project.find_by_full_path(project_path)

          return unless project

          ::IncidentManagement::OncallSchedulesFinder.new(current_user, project, args).execute.first
        end
      end
    end
  end
end
