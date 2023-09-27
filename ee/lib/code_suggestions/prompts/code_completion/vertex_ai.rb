# frozen_string_literal: true

module CodeSuggestions
  module Prompts
    module CodeCompletion
      class VertexAi < CodeSuggestions::Prompts::Base
        GATEWAY_PROMPT_VERSION = 1

        def request_params
          {
            prompt_version: GATEWAY_PROMPT_VERSION
          }
        end
      end
    end
  end
end
