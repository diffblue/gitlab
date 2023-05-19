# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module Completions
        class GenerateCommitMessage < Gitlab::Llm::Completions::Base
          DEFAULT_ERROR = 'An unexpected error has occurred.'

          def execute(user, merge_request, options)
            response = response_for(user, merge_request)
            response_modifier = Gitlab::Llm::OpenAi::ResponseModifiers::Chat.new(response)

            ::Gitlab::Llm::GraphqlSubscriptionResponseService.new(
              user, merge_request, response_modifier, options: options
            ).execute
          rescue StandardError => error
            Gitlab::ErrorTracking.track_exception(error)

            response_modifier = ::Gitlab::Llm::OpenAi::ResponseModifiers::Chat.new(
              { error: { message: DEFAULT_ERROR } }.to_json
            )

            ::Gitlab::Llm::GraphqlSubscriptionResponseService.new(
              user, merge_request, response_modifier, options: options
            ).execute
          end

          private

          def response_for(user, merge_request)
            template = ai_prompt_class.new(merge_request)
            client_class = ::Gitlab::Llm::OpenAi::Client
            client_class.new(user)
              .chat(content: template.to_prompt, **template.options(client_class))
          end
        end
      end
    end
  end
end
