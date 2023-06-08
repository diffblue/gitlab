# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      class GitlabContext
        attr_accessor :current_user, :container, :resource, :ai_request

        def initialize(current_user:, container:, resource:, ai_request:)
          @current_user = current_user
          @container = container
          @resource = resource
          @ai_request = ai_request
        end
      end
    end
  end
end
