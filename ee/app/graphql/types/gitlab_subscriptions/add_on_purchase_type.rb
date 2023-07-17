# frozen_string_literal: true

module Types
  module GitlabSubscriptions
    class AddOnPurchaseType < Types::BaseObject
      graphql_name 'AddOnPurchase'
      description 'Represents AddOn purchase for Namespace'

      authorize :admin_add_on_purchase

      field :assigned_quantity, GraphQL::Types::Int,
        null: false, description: 'Number of seats assigned.'
      field :id, ::Types::GlobalIDType[::GitlabSubscriptions::AddOnPurchase],
        null: false, description: 'ID of AddOnPurchase.'
      field :name, GraphQL::Types::String, null: false, description: 'Name of AddOn.'
      field :purchased_quantity, GraphQL::Types::Int,
        null: false, method: :quantity, description: 'Number of seats purchased.'

      def assigned_quantity
        object.assigned_users.count
      end

      def name
        object.add_on.name.upcase
      end
    end
  end
end
