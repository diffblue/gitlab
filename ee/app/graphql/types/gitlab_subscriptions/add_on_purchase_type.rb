# frozen_string_literal: true

module Types
  module GitlabSubscriptions
    class AddOnPurchaseType < Types::BaseObject
      graphql_name 'AddOnPurchase'
      description 'Represents AddOn purchase for Namespace'

      authorize :admin_add_on_purchase

      field :id, ::Types::GlobalIDType[::GitlabSubscriptions::AddOnPurchase],
        null: false, description: 'ID of AddOnPurchase.'
      field :name, GraphQL::Types::String, null: false, description: 'Name of AddOn.'
      field :purchased_quantity, GraphQL::Types::Int,
        null: false, method: :quantity, description: 'Number of seats purchased.'

      field :assigned_quantity,
        type: GraphQL::Types::Int,
        null: false,
        description: 'Number of seats assigned.'

      alias_method :add_on_purchase, :object

      def assigned_quantity
        context[:assigned_add_on_counts] ||= {}
        context[:assigned_add_on_counts][add_on_purchase.id] ||= add_on_purchase.assigned_users.size
      end

      def name
        add_on_purchase.add_on.name.upcase
      end
    end
  end
end
