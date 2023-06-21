# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      module ModelConfigurations
        class CodeCompletion < Base
          NAME = 'code-gecko'
          MAX_OUTPUT_TOKENS = 64

          def payload(content)
            {
              instances: [
                {
                  prefix: content[:prefix],
                  suffix: content[:suffix]
                }
              ],
              parameters: Configuration.payload_parameters(maxOutputTokens: MAX_OUTPUT_TOKENS)
            }
          end
        end
      end
    end
  end
end
