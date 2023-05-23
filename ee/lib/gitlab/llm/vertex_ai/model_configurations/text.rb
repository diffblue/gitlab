# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      module ModelConfigurations
        class Text < Base
          NAME = 'text-bison'

          def payload(content)
            {
              instances: [
                {
                  content: content
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
