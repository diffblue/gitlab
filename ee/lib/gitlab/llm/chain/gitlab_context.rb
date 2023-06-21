# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      class GitlabContext
        attr_accessor :current_user, :container, :resource, :ai_request, :tools_used

        def initialize(current_user:, container:, resource:, ai_request:, tools_used: [])
          @current_user = current_user
          @container = container
          @resource = resource
          @ai_request = ai_request
          @tools_used = tools_used
        end
      end
    end
  end
end
