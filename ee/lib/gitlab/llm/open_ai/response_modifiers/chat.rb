# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module ResponseModifiers
        class Chat
          def execute(ai_response)
            ai_response&.dig(:choices, 0, :message, :content)
          end
        end
      end
    end
  end
end
