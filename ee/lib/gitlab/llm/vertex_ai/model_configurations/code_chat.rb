# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      module ModelConfigurations
        class CodeChat < Base
          NAME = 'codechat-bison-001'

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

          def url
            tofa_url
          end

          def host
            tofa_host
          end
        end
      end
    end
  end
end
