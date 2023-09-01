# frozen_string_literal: true

module Ai
  module AiResource
    class Epic < Ai::AiResource::BaseAiResource
      include Ai::AiResource::Concerns::Noteable

      def serialize_for_ai(user:, content_limit:)
        ::EpicSerializer.new(current_user: user) # rubocop: disable CodeReuse/Serializer
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
