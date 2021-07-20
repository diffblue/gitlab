# frozen_string_literal: true

module Resolvers
  class MergeRequestsCountResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    type GraphQL::Types::Int, null: true

    def resolve
      authorize!(object)

      BatchLoader::GraphQL.for(object.id).batch do |ids, loader, args|
        counts = MergeRequestsClosingIssues.count_for_collection(ids, context[:current_user]).to_h

        ids.each do |id|
          loader.call(id, counts[id] || 0)
        end
      end
    end

    def authorized_resource?(object)
      ability = "read_#{object.class.name.underscore}".to_sym
      context[:current_user].present? && Ability.allowed?(context[:current_user], ability, object)
    end
  end
end
