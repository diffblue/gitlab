# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      module Completions
        class ExplainCode < Gitlab::Llm::Completions::Base
          def execute(user, project, options)
            options = ai_prompt_class.get_options(options[:messages])

            response = Gitlab::Llm::VertexAi::Client.new(user).chat(content: nil, **options)
            response_modifier = ::Gitlab::Llm::VertexAi::ResponseModifiers::Predictions.new(response)

            ::Gitlab::Llm::GraphqlSubscriptionResponseService
              .new(user, project, response_modifier, options: response_options)
              .execute
          end
        end
      end
    end
  end
end
