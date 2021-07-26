# frozen_string_literal: true

module Mutations
  module Boards
    module EpicBoards
      class Create < ::Mutations::BaseMutation
        include Mutations::ResolvesGroup
        include Mutations::Boards::CommonMutationArguments
        prepend Mutations::Boards::ScopedBoardMutation

        graphql_name 'EpicBoardCreate'

        authorize :admin_epic_board

        argument :group_path, GraphQL::Types::ID,
                 required: false,
                 description: 'Full path of the group with which the resource is associated.'

        field :epic_board,
              Types::Boards::EpicBoardType,
              null: true,
              description: 'The created epic board.'

        def resolve(args)
          group_path = args.delete(:group_path)

          group = authorized_find!(group_path: group_path)
          service_response = ::Boards::EpicBoards::CreateService.new(group, current_user, args).execute

          {
            epic_board: service_response.success? ? service_response.payload : nil,
            errors: service_response.errors
          }
        end

        private

        def find_object(group_path:)
          resolve_group(full_path: group_path)
        end
      end
    end
  end
end
