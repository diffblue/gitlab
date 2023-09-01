# frozen_string_literal: true

module Ai
  module AiResource
    class Issue < Ai::AiResource::BaseAiResource
      include Ai::AiResource::Concerns::Noteable

      def serialize_for_ai(user:, content_limit:)
        ::IssueSerializer.new(current_user: user, project: resource.project) # rubocop: disable CodeReuse/Serializer
                         .represent(resource, {
                           user: user,
                           notes_limit: content_limit,
                           serializer: 'ai',
                           resource: self
                         })
      end
    end
  end
end
