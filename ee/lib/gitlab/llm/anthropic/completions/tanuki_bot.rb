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

            response_modifier = ::Gitlab::Llm::TanukiBot.new(
              current_user: user,
              question: question,
              tracking_context: tracking_context
            ).execute

            ::Gitlab::Llm::GraphqlSubscriptionResponseService.new(
              user, resource, response_modifier, options: response_options
            ).execute

            response_modifier
          end
        end
      end
    end
  end
end
