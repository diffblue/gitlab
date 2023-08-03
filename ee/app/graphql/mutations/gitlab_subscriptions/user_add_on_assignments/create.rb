# frozen_string_literal: true

module Mutations
  module GitlabSubscriptions
    module UserAddOnAssignments
      class Create < BaseMutation
        graphql_name 'UserAddOnAssignmentCreate'

        argument :add_on_purchase_id, ::Types::GlobalIDType[::GitlabSubscriptions::AddOnPurchase],
          required: true, description: 'Global ID of AddOnPurchase to be assinged to.'

        argument :user_id, ::Types::GlobalIDType[::User],
          required: true, description: 'Global ID of user to be assigned.'

        field :add_on_purchase, ::Types::GitlabSubscriptions::AddOnPurchaseType,
          null: true,
          description: 'AddOnPurchase state after mutation.'

        authorize :admin_add_on_purchase

        def resolve(**)
          create_service = ::GitlabSubscriptions::UserAddOnAssignments::CreateService.new(
            add_on_purchase: add_on_purchase,
            user: user_to_be_assigned
          ).execute

          {
            add_on_purchase: create_service.success? ? add_on_purchase : nil,
            errors: create_service.errors
          }
        end

        def ready?(add_on_purchase_id:, user_id:)
          @add_on_purchase = authorized_find!(id: add_on_purchase_id)
          @user_to_be_assigned = ::Gitlab::Graphql::Lazy.force(GitlabSchema.find_by_gid(user_id))

          raise_resource_not_available_error! unless feature_enabled? && add_on_purchase&.active? && user_to_be_assigned

          super
        end

        private

        attr_reader :add_on_purchase, :user_to_be_assigned

        def feature_enabled?
          Feature.enabled?(:hamilton_seat_management)
        end
      end
    end
  end
end
