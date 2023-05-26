# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      class GitlabContext
        attr_accessor :current_user, :container, :resource, :ai_client

        def initialize(current_user:, container:, resource:, ai_client:)
          @current_user = current_user
          @container = container
          @resource = resource
          @ai_client = ai_client
        end
      end
    end
  end
end
