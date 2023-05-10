# frozen_string_literal: true

module Resolvers
  module Ai
    class ProjectConversationsResolver < BaseResolver
      alias_method :project, :object

      type Types::Ai::ProjectConversationsType, null: false

      def resolve
        ::Ai::Project::Conversations.new(project, context[:current_user])
      end
    end
  end
end
