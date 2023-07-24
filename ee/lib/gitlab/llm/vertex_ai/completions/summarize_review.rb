# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      module Completions
        class SummarizeReview < Gitlab::Llm::Completions::Base
          DEFAULT_ERROR = 'An unexpected error has occurred.'

          def execute(user, merge_request, options)
            unless vertex_ai?(merge_request)
              return ::Gitlab::Llm::OpenAi::Completions::SummarizeReview
                .new(ai_prompt_class)
                .execute(user, merge_request, options)
            end

            draft_notes = merge_request.draft_notes.authored_by(user)
            return if draft_notes.empty?

            response = response_for(user, draft_notes)
            response_modifier = ::Gitlab::Llm::VertexAi::ResponseModifiers::Predictions.new(response)

            ::Gitlab::Llm::GraphqlSubscriptionResponseService.new(
              user, merge_request, response_modifier, options: options
            ).execute
          rescue StandardError => error
            Gitlab::ErrorTracking.track_exception(error)

            response_modifier = ::Gitlab::Llm::VertexAi::ResponseModifiers::Predictions.new(
              { error: { message: DEFAULT_ERROR } }.to_json
            )

            ::Gitlab::Llm::GraphqlSubscriptionResponseService.new(
              user, merge_request, response_modifier, options: options
            ).execute
          end

          private

          def response_for(user, draft_notes)
            Gitlab::Llm::VertexAi::Client
              .new(user)
              .text(content: ai_prompt_class.new(draft_notes).to_prompt)
          end

          def vertex_ai?(merge_request)
            Feature.enabled?(:summarize_review_vertex, merge_request.project)
          end
        end
      end
    end
  end
end
