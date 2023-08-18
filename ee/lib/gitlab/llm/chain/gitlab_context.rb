# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      class GitlabContext
        attr_accessor :current_user, :container, :resource, :ai_request, :tools_used, :extra_resource

        def initialize(current_user:, container:, resource:, ai_request:, tools_used: [], extra_resource: {})
          @current_user = current_user
          @container = container
          @resource = resource
          @ai_request = ai_request
          @tools_used = tools_used
          @extra_resource = extra_resource
        end
      end
    end
  end
end
