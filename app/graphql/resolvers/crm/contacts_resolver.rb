# frozen_string_literal: true

module Resolvers
  module Crm
    class ContactsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :read_crm_contact

      type Types::CustomerRelations::ContactType, null: true

      argument :name, GraphQL::Types::String,
               required: false,
               description: 'Name of the Contact.'

      argument :email, GraphQL::Types::String,
               required: false,
               description: 'Email of the Contact.'

      def resolve(**args)
        ::Crm::ContactsFinder.new(current_user, { group: group }.merge(args)).execute
      end

      def group
        object.respond_to?(:sync) ? object.sync : object
      end
    end
  end
end
