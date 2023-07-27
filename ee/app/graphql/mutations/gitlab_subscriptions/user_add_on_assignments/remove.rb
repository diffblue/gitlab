# frozen_string_literal: true

module Mutations
  module GitlabSubscriptions
    module UserAddOnAssignments
      class Remove < BaseMutation
        graphql_name 'UserAddOnAssignmentRemove'

        argument :add_on_purchase_id, ::Types::GlobalIDType[::GitlabSubscriptions::AddOnPurchase],
          required: true, description: 'Global ID of AddOnPurchase assignment belongs to.'

        argument :user_id, ::Types::GlobalIDType[::User],
          required: true, description: 'Global ID of user whose assignment will be removed.'

        def resolve(**)
          authorize!

          assignment = add_on_purchase.assigned_users.by_user(user_to_be_removed).first

          return unless assignment

          assignment.destroy!

          {
            errors: []
          }
        end

        def ready?(add_on_purchase_id:, user_id:)
          @add_on_purchase = ::Gitlab::Graphql::Lazy.force(GitlabSchema.find_by_gid(add_on_purchase_id))
          @user_to_be_removed = ::Gitlab::Graphql::Lazy.force(GitlabSchema.find_by_gid(user_id))

          raise_resource_not_available_error! unless feature_enabled? &&
            add_on_purchase&.active? && user_to_be_removed

          super
        end

        private

        attr_reader :add_on_purchase, :user_to_be_removed

        def feature_enabled?
          Feature.enabled?(:hamilton_seat_management)
        end

        def authorize!
          return if self_removal? ||
            Ability.allowed?(current_user, :admin_add_on_purchase, add_on_purchase.namespace)

          raise_resource_not_available_error!
        end

        def self_removal?
          current_user == user_to_be_removed
        end
      end
    end
  end
end
