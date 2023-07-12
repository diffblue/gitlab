# frozen_string_literal: true

module Gitlab
  module Llm
    module Anthropic
      module Completions
        class TanukiBot < Gitlab::Llm::Completions::Base
          # After we remove REST API, refactor so that we use methods defined in templates/tanuki_bot.rb, e.g.:
          # initial_prompt = ai_prompt_class.initial_prompt(question)
          def execute(user, resource, options)
            question = options[:question]

            response = ::Gitlab::Llm::TanukiBot.execute(current_user: user, question: question)
            response_modifier = Gitlab::Llm::Anthropic::ResponseModifiers::TanukiBot.new(response)

            ::Gitlab::Llm::GraphqlSubscriptionResponseService.new(
              user, resource, response_modifier, options: response_options
            ).execute
          end
        end
      end
    end
  end
end
