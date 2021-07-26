# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module OncallSchedule
      class Destroy < OncallScheduleBase
        graphql_name 'OncallScheduleDestroy'

        argument :project_path, GraphQL::Types::ID,
                 required: true,
                 description: 'The project to remove the on-call schedule from.'

        argument :iid, GraphQL::Types::String,
                 required: true,
                 description: 'The on-call schedule internal ID to remove.'

        def resolve(project_path:, iid:)
          oncall_schedule = authorized_find!(project_path: project_path, iid: iid)

          response ::IncidentManagement::OncallSchedules::DestroyService.new(
            oncall_schedule,
            current_user
          ).execute
        end
      end
    end
  end
end
