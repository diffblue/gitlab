# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Agents
        class ZeroShot
          attr_reader :tools, :input_prompt

          def initialize(tools:, input_prompt:)
            @tools = tools
            @input_prompt = input_prompt
          end
        end
      end
    end
  end
end
