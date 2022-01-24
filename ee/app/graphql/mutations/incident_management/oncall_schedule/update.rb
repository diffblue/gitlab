# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module OncallSchedule
      class Update < OncallScheduleBase
        graphql_name 'OncallScheduleUpdate'

        argument :project_path, GraphQL::Types::ID,
                 required: true,
                 description: 'Project to update the on-call schedule in.'

        argument :iid, GraphQL::Types::String,
                 required: true,
                 description: 'On-call schedule internal ID to update.'

        argument :name, GraphQL::Types::String,
                 required: false,
                 description: 'Name of the on-call schedule.'

        argument :description, GraphQL::Types::String,
                 required: false,
                 description: 'Description of the on-call schedule.'

        argument :timezone, GraphQL::Types::String,
                 required: false,
                 description: 'Timezone of the on-call schedule.'

        def resolve(args)
          oncall_schedule = authorized_find!(project_path: args[:project_path], iid: args[:iid])

          response ::IncidentManagement::OncallSchedules::UpdateService.new(
            project: oncall_schedule.project,
            current_user: current_user,
            params: args.slice(:name, :description, :timezone)
          ).execute(oncall_schedule)
        end
      end
    end
  end
end
