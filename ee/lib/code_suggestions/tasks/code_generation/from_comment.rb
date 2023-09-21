# frozen_string_literal: true

module CodeSuggestions
  module Tasks
    module CodeGeneration
      class FromComment < CodeSuggestions::Tasks::Base
        extend ::Gitlab::Utils::Override

        override :endpoint_name
        def endpoint_name
          'generations'
        end

        override :body
        def body
          prompt = CodeSuggestions::Prompts::CodeGeneration::VertexAi.new(params)

          unsafe_passthrough_params.merge(prompt.request_params).to_json
        end
      end
    end
  end
end
