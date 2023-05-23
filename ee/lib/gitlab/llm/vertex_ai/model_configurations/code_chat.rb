# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      module ModelConfigurations
        class CodeChat < Base
          NAME = 'codechat-bison'

          def payload(content)
            {
              instances: [
                {
                  messages: [
                    {
                      author: "content",
                      content: content
                    }
                  ]
                }
              ],
              parameters: Configuration.default_payload_parameters
            }
          end
        end
      end
    end
  end
end
