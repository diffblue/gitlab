# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module OncallSchedule
      class Destroy < OncallScheduleBase
        graphql_name 'OncallScheduleDestroy'

        argument :project_path, GraphQL::Types::ID,
                 required: true,
                 description: 'Project to remove the on-call schedule from.'

        argument :iid, GraphQL::Types::String,
                 required: true,
                 description: 'On-call schedule internal ID to remove.'

        def resolve(project_path:, iid:)
          oncall_schedule = authorized_find!(project_path: project_path, iid: iid)

          response ::IncidentManagement::OncallSchedules::DestroyService.new(
            project: oncall_schedule.project,
            current_user: current_user
          ).execute(oncall_schedule)
        end
      end
    end
  end
end
