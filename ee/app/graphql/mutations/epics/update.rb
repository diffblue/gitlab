# frozen_string_literal: true

module Mutations
  module Epics
    class Update < Base
      graphql_name 'UpdateEpic'

      prepend Mutations::SharedEpicArguments

      argument :state_event,
                Types::EpicStateEventEnum,
                required: false,
                description: 'State event for the epic.'

      argument :remove_labels,
                [GraphQL::Types::String],
                required: false,
                description: 'Array of labels to be removed from the epic.'

      authorize :admin_epic

      def resolve(args)
        group_path = args.delete(:group_path)
        epic_iid = args.delete(:iid)

        epic = authorized_find!(group_path: group_path, iid: epic_iid)

        validate_arguments!(args, epic.group)

        epic = ::Epics::UpdateService.new(group: epic.group, current_user: current_user, params: args).execute(epic)

        {
          epic: epic.reset,
          errors: errors_on_object(epic)
        }
      end
    end
  end
end
