# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      module ModelConfigurations
        class Chat < Base
          NAME = 'chat-bison'

          def payload(content)
            {
              instances: [
                {
                  messages: content
                }
              ],
              parameters: Configuration.payload_parameters
            }
          end
        end
      end
    end
  end
end
