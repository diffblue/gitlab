# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      class GitlabContext
        attr_reader :current_user, :namespace, :resource

        def initialize(current_user:, namespace:, resource:)
          @current_user = current_user
          @namespace = namespace
          @resource = resource
        end
      end
    end
  end
end
