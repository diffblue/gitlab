# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module OncallSchedule
      class Update < OncallScheduleBase
        graphql_name 'OncallScheduleUpdate'

        argument :project_path, GraphQL::Types::ID,
                 required: true,
                 description: 'The project to update the on-call schedule in.'

        argument :iid, GraphQL::Types::String,
                 required: true,
                 description: 'The on-call schedule internal ID to update.'

        argument :name, GraphQL::Types::String,
                 required: false,
                 description: 'The name of the on-call schedule.'

        argument :description, GraphQL::Types::String,
                 required: false,
                 description: 'The description of the on-call schedule.'

        argument :timezone, GraphQL::Types::String,
                 required: false,
                 description: 'The timezone of the on-call schedule.'

        def resolve(args)
          oncall_schedule = authorized_find!(project_path: args[:project_path], iid: args[:iid])

          response ::IncidentManagement::OncallSchedules::UpdateService.new(
            oncall_schedule,
            current_user,
            args.slice(:name, :description, :timezone)
          ).execute
        end
      end
    end
  end
end
