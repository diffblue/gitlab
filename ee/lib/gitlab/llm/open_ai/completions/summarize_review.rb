# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module Completions
        class SummarizeReview < Gitlab::Llm::Completions::Base
          def execute(user, merge_request, _ = {})
            return unless user
            return unless merge_request

            draft_notes = merge_request.draft_notes.authored_by(user)
            return if draft_notes.empty?

            response = response_for(user, draft_notes)
            response_modifier = Gitlab::Llm::OpenAi::ResponseModifiers::Chat.new(response)

            ::Gitlab::Llm::GraphqlSubscriptionResponseService.new(
              user, merge_request, response_modifier, options: response_options
            ).execute
          end

          private

          def response_for(user, draft_notes)
            Gitlab::Llm::OpenAi::Client
              .new(user)
              .chat(
                content: ai_prompt_class.new(draft_notes).to_prompt,
                moderated: true
              )
          end
        end
      end
    end
  end
end
