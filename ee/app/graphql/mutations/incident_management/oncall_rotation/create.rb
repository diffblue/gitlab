# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module OncallRotation
      class Create < Base
        graphql_name 'OncallRotationCreate'

        include ResolvesProject

        argument :project_path, GraphQL::Types::ID,
                 required: true,
                 description: 'Project to create the on-call schedule in.'

        argument :schedule_iid, GraphQL::Types::String,
                 required: true,
                 description: 'IID of the on-call schedule to create the on-call rotation in.',
                 as: :iid

        argument :name, GraphQL::Types::String,
                 required: true,
                 description: 'Name of the on-call rotation.'

        argument :starts_at, Types::IncidentManagement::OncallRotationDateInputType,
                 required: true,
                 description: 'Start date and time of the on-call rotation, in the timezone of the on-call schedule.'

        argument :ends_at, Types::IncidentManagement::OncallRotationDateInputType,
                 required: false,
                 description: 'End date and time of the on-call rotation, in the timezone of the on-call schedule.'

        argument :rotation_length, Types::IncidentManagement::OncallRotationLengthInputType,
                 required: true,
                 description: 'Rotation length of the on-call rotation.'

        argument :active_period, Types::IncidentManagement::OncallRotationActivePeriodInputType,
                 required: false,
                 description: 'Active period of time that the on-call rotation should take place.'

        argument :participants,
                 [Types::IncidentManagement::OncallUserInputType],
                 required: true,
                 description: 'Usernames of users participating in the on-call rotation. A maximum limit of 100 participants applies.'

        def resolve(iid:, project_path:, participants:, **args)
          project = Project.find_by_full_path(project_path)

          raise_project_not_found unless project

          schedule = ::IncidentManagement::OncallSchedulesFinder.new(current_user, project, iid: iid)
                                                                .execute
                                                                .first

          raise_schedule_not_found unless schedule

          result = ::IncidentManagement::OncallRotations::CreateService.new(
            schedule,
            project,
            current_user,
            parsed_params(schedule, participants, args)
          ).execute

          response(result)

        rescue ActiveRecord::RecordInvalid => e
          raise Gitlab::Graphql::Errors::ArgumentError, e.message
        end
      end
    end
  end
end
