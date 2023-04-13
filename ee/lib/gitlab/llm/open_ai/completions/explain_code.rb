# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module Completions
        class ExplainCode
          def initialize(ai_prompt_class)
            @ai_prompt_class = ai_prompt_class
          end

          def execute(user, project, options)
            options = ai_prompt_class.get_options(options[:messages])

            ai_response = Gitlab::Llm::OpenAi::Client.new(user).chat(content: nil, **options)

            ::Gitlab::Llm::OpenAi::ResponseService.new(user, project, ai_response, options: {}).execute(
              Gitlab::Llm::OpenAi::ResponseModifiers::Chat.new
            )
          end

          private

          attr_reader :ai_prompt_class
        end
      end
    end
  end
end
