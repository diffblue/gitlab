# frozen_string_literal: true

module Resolvers
  module Crm
    class OrganizationsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :read_crm_organization

      type Types::CustomerRelations::OrganizationType, null: true

      argument :name, GraphQL::Types::String,
              required: false,
              description: 'Name of the Organization.'

      def resolve(**args)
        ::Crm::OrganizationsFinder.new(current_user, { group: group }.merge(args)).execute
      end

      def group
        object.respond_to?(:sync) ? object.sync : object
      end
    end
  end
end
