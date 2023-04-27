# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module Completions
        class TanukiBot
          def initialize(ai_prompt_class)
            @ai_prompt_class = ai_prompt_class
          end

          # After we remove REST API, refactor so that we use methods defined in templates/tanuki_bot.rb, e.g.:
          # initial_prompt = ai_prompt_class.initial_prompt(question)
          def execute(user, resource, options)
            question = options[:question]

            response = ::Gitlab::Llm::TanukiBot.execute(current_user: user, question: question)

            ::Gitlab::Llm::OpenAi::ResponseService.new(user, resource, response, options: {}).execute(
              Gitlab::Llm::OpenAi::ResponseModifiers::TanukiBot.new
            )
          end

          private

          attr_reader :ai_prompt_class
        end
      end
    end
  end
end
