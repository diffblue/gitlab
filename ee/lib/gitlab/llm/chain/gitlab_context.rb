# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      class GitlabContext
        attr_reader :current_user, :namespace, :resource, :ai_client

        def initialize(current_user:, namespace:, resource:, ai_client:)
          @current_user = current_user
          @namespace = namespace
          @resource = resource
          @ai_client = ai_client
        end
      end
    end
  end
end
