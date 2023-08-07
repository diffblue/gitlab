# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Agents
        module ZeroShot
          module Prompts
            class VertexAi < Base
              def self.prompt(options)
                Requests::VertexAi.prompt(base_prompt(options))
              end
            end
          end
        end
      end
    end
  end
end
