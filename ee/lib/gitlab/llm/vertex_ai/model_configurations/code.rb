# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      module ModelConfigurations
        class Code < Base
          NAME = 'code-bison'

          def payload(content)
            {
              instances: [
                {
                  prefix: content
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
