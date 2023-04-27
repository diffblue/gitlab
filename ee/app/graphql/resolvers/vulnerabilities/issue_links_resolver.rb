# frozen_string_literal: true

module Resolvers
  module Vulnerabilities
    class IssueLinksResolver < BaseResolver
      type Types::Vulnerability::IssueLinkType, null: true

      argument :link_type, Types::Vulnerability::IssueLinkTypeEnum,
               required: false,
               description: 'Filter issue links by link type.'

      def resolve(link_type: nil, **)
        Gitlab::Graphql::Loaders::Vulnerabilities::IssueLinksLoader.new(context, object, link_type: link_type)
      end
    end
  end
end
