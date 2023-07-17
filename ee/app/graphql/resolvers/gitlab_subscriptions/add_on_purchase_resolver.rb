# frozen_string_literal: true

module Resolvers
  module GitlabSubscriptions
    class AddOnPurchaseResolver < BaseResolver
      type Types::GitlabSubscriptions::AddOnPurchaseType, null: true

      argument :add_on_name, GraphQL::Types::String, required: true, description: 'AddOn name.',
        prepare: ->(add_on_name, _ctx) { add_on_name.downcase }

      alias_method :namespace, :object

      def resolve(add_on_name:)
        return unless namespace.root?

        namespace.subscription_add_on_purchases.active.by_add_on_name(add_on_name).first
      end
    end
  end
end
