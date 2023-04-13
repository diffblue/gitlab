# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module ResponseModifiers
        class Completions
          def execute(ai_response)
            ai_response&.dig(:choices, 0, :text)
          end
        end
      end
    end
  end
end
