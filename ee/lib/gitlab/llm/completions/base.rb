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
      end
    end
  end
end
