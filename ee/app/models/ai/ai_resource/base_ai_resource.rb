# frozen_string_literal: true

module Ai
  module AiResource
    class BaseAiResource
      attr_reader :resource

      def initialize(resource)
        @resource = resource
      end

      def serialize_for_ai(_user:, _content_limit:)
        raise NotImplementedError
      end
    end
  end
end
