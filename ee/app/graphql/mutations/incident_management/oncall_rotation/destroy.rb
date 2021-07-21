# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module OncallRotation
      class Destroy < Base
        graphql_name 'OncallRotationDestroy'

        argument :project_path, GraphQL::Types::ID,
                 required: true,
                 description: 'The project to remove the on-call schedule from.'

        argument :schedule_iid, GraphQL::Types::String,
                 required: true,
                 description: 'The IID of the on-call schedule to the on-call rotation belongs to.'

        argument :id, Types::GlobalIDType[::IncidentManagement::OncallRotation],
                 required: true,
                 description: 'The ID of the on-call rotation to remove.'

        def resolve(project_path:, schedule_iid:, id:)
          oncall_rotation = authorized_find!(project_path: project_path, schedule_iid: schedule_iid, id: id)

          response ::IncidentManagement::OncallRotations::DestroyService.new(
            oncall_rotation,
            current_user
          ).execute
        end
      end
    end
  end
end
