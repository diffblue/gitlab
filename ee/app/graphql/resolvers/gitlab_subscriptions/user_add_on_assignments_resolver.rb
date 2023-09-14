# frozen_string_literal: true

module Resolvers
  module GitlabSubscriptions
    class UserAddOnAssignmentsResolver < BaseResolver
      include LooksAhead
      include Gitlab::Graphql::Authorize::AuthorizeResource

      argument :add_on_purchase_ids,
        type: [::Types::GlobalIDType[::GitlabSubscriptions::AddOnPurchase]],
        required: true,
        description: 'Global IDs of the add on purchases to find assignments for.',
        prepare: ->(global_ids, _ctx) do
          GitlabSchema.parse_gids(global_ids, expected_type: ::GitlabSubscriptions::AddOnPurchase).map(&:model_id)
        end

      type ::Types::GitlabSubscriptions::UserAddOnAssignmentType.connection_type, null: true

      before_connection_authorization do |nodes, current_user|
        namespaces = nodes.map { |assignment| assignment.add_on_purchase.namespace }

        Preloaders::GroupPolicyPreloader.new(namespaces, current_user).execute
      end

      alias_method :user, :object

      def resolve_with_lookahead(**args)
        return [] unless Feature.enabled?(:hamilton_seat_management)

        query = ::GitlabSubscriptions::UserAddOnAssignment
                  .for_user_ids(user.id)
                  .for_active_add_on_purchase_ids(args[:add_on_purchase_ids])

        apply_lookahead(query)
      end

      private

      def nested_preloads
        {
          add_on_purchase: {
            assigned_quantity: [{ add_on_purchase: :assigned_users }]
          }
        }
      end

      def preloads
        { add_on_purchase: [add_on_purchase: [:add_on, :namespace]] }
      end
    end
  end
end
