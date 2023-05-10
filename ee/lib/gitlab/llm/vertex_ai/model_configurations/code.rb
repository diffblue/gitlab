# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      module ModelConfigurations
        class Code < Base
          include Gitlab::Utils::StrongMemoize

          NAME = 'code-bison-001'

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

          def url
            text_model_url = URI.parse(tofa_url)
            text_model_url.host = text_model_url.host.gsub('-preprod-', '-')
            text_model_url.path = text_model_url.path.gsub(ModelConfigurations::CodeChat::NAME, NAME)
            text_model_url.to_s
          end
          strong_memoize_attr :url

          def host
            URI.parse(url).hostname
          end
          strong_memoize_attr :host
        end
      end
    end
  end
end
