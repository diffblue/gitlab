# frozen_string_literal: true

module Mutations
  module Epics
    class SetSubscription < Base
      graphql_name 'EpicSetSubscription'

      authorize :read_epic

      argument :subscribed_state, GraphQL::Types::Boolean,
               required: true,
               description: 'The desired state of the subscription.'

      def resolve(args)
        group_path = args.delete(:group_path)
        epic_iid = args.delete(:iid)
        desired_state = args.delete(:subscribed_state)

        epic = authorized_find!(group_path: group_path, iid: epic_iid)
        epic.set_subscription(current_user, desired_state)

        {
          epic: epic.reset,
          errors: errors_on_object(epic)
        }
      end
    end
  end
end
