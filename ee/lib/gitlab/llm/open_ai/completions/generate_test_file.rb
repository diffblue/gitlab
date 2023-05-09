# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module Completions
        class GenerateTestFile < Gitlab::Llm::Completions::Base
          TOTAL_MODEL_TOKEN_LIMIT = 4000
          OUTPUT_TOKEN_LIMIT = (TOTAL_MODEL_TOKEN_LIMIT * 0.25).to_i.freeze

          def execute(user, merge_request, options)
            return unless user
            return unless merge_request
            return unless merge_request.send_to_ai?

            ai_options = ai_prompt_class.get_options(merge_request, options[:file_path])
            ai_options[:max_tokens] = OUTPUT_TOKEN_LIMIT

            ai_response = Gitlab::Llm::OpenAi::Client.new(user).chat(content: nil, **ai_options)

            options[:request_id] = params[:request_id]

            ::Gitlab::Llm::OpenAi::ResponseService.new(user, merge_request, ai_response, options: options).execute(
              Gitlab::Llm::OpenAi::ResponseModifiers::Chat.new
            )
          end
        end
      end
    end
  end
end
