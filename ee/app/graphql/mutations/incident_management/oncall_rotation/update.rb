# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module OncallRotation
      class Update < Base
        graphql_name 'OncallRotationUpdate'

        include ResolvesProject

        argument :id, ::Types::GlobalIDType[::IncidentManagement::OncallRotation],
                 required: true,
                 description: 'ID of the on-call schedule to create the on-call rotation in.'

        argument :name, GraphQL::Types::String,
                 required: false,
                 description: 'Name of the on-call rotation.'

        argument :starts_at, Types::IncidentManagement::OncallRotationDateInputType,
                 required: false,
                 description: 'Start date and time of the on-call rotation, in the timezone of the on-call schedule.'

        argument :ends_at, Types::IncidentManagement::OncallRotationDateInputType,
                 required: false,
                 description: 'End date and time of the on-call rotation, in the timezone of the on-call schedule.'

        argument :rotation_length, Types::IncidentManagement::OncallRotationLengthInputType,
                 required: false,
                 description: 'Rotation length of the on-call rotation.'

        argument :active_period, Types::IncidentManagement::OncallRotationActivePeriodInputType,
                 required: false,
                 description: 'Active period of time that the on-call rotation should take place.'

        argument :participants,
                 [Types::IncidentManagement::OncallUserInputType],
                 required: false,
                 description: 'Usernames of users participating in the on-call rotation. A maximum limit of 100 participants applies.'

        def resolve(id:, **args)
          rotation = authorized_find!(id: id)

          result = ::IncidentManagement::OncallRotations::EditService.new(
            rotation,
            current_user,
            parsed_params(rotation.schedule, args[:participants], args)
          ).execute

          response(result)
        end

        private

        def find_object(id:)
          GitlabSchema.object_from_id(id, expected_type: ::IncidentManagement::OncallRotation)
        end

        def raise_rotation_not_found
          raise Gitlab::Graphql::Errors::ArgumentError, 'The rotation could not be found'
        end
      end
    end
  end
end
