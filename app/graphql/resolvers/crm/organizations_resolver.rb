# frozen_string_literal: true

module Resolvers
  module Crm
    class OrganizationsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :read_crm_organization

      type Types::CustomerRelations::OrganizationType, null: true

      argument :search, GraphQL::Types::String,
               required: false,
               description: 'Search term used to find organizations with.'

      argument :state, Types::CustomerRelations::OrganizationStateEnum,
               required: false,
               description: 'State of the organization to search for.'

      argument :ids, [GraphQL::Types::ID],
               required: false,
               description: 'Filter organizations by IDs.'

      def resolve(**args)
        args[:ids] = parse_gids(args.delete(:ids))

        ::Crm::OrganizationsFinder.new(current_user, { group: group }.merge(args)).execute
      end

      def group
        object.respond_to?(:sync) ? object.sync : object
      end

      private

      def parse_gids(gids)
        gids&.map { |gid| GitlabSchema.parse_gid(gid, expected_type: CustomerRelations::Organization).model_id }
      end
    end
  end
end
