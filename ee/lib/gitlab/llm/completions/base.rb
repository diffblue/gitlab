# frozen_string_literal: true

module Gitlab
  module Llm
    module Completions
      class Base
        def initialize(ai_prompt_class, params = {})
          @ai_prompt_class = ai_prompt_class
          @params = params
        end

        private

        attr_reader :ai_prompt_class, :params

        def response_options
          params.slice(:request_id, :internal_request, :cache_response)
        end
      end
    end
  end
end
