# frozen_string_literal: true

module Mutations
  module Epics
    class Create < BaseMutation
      graphql_name 'CreateEpic'

      include Mutations::ResolvesGroup
      prepend Mutations::SharedEpicArguments

      authorize :create_epic

      field :epic,
            Types::EpicType,
            null: true,
            description: 'Created epic.'

      def resolve(args)
        group_path = args.delete(:group_path)

        group = authorized_find!(group_path: group_path)

        validate_arguments!(args, group)

        epic = ::Epics::CreateService.new(group: group, current_user: current_user, params: args).execute

        response_object = epic if epic.valid?

        {
          epic: response_object,
          errors: errors_on_object(epic)
        }
      end

      private

      def find_object(group_path:)
        resolve_group(full_path: group_path)
      end
    end
  end
end
