# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      module Completions
        class SummarizeSubmittedReview < Gitlab::Llm::Completions::Base
          # rubocop:disable CodeReuse/ActiveRecord
          def execute(user, merge_request, options)
            review = merge_request.reviews.find_by(id: options[:review_id])
            mr_diff = merge_request.merge_request_diffs.find_by(id: options[:diff_id])

            return unless review.present? && mr_diff.present?

            response = response_for(user, review)
            response_modifier = ::Gitlab::Llm::VertexAi::ResponseModifiers::Predictions.new(response)

            store_response(response_modifier, review, mr_diff)
          end
          # rubocop:enable CodeReuse/ActiveRecord

          private

          def response_for(user, review)
            template = ai_prompt_class.new(review)
            request(user, template)
          end

          def request(user, template)
            ::Gitlab::Llm::VertexAi::Client
              .new(user)
              .chat(content: template.to_prompt)
          end

          def store_response(response_modifier, review, mr_diff)
            return if response_modifier.errors.any?

            ::MergeRequest::ReviewLlmSummary.create!(
              review: review,
              merge_request_diff: mr_diff,
              user: User.llm_bot,
              provider: MergeRequest::ReviewLlmSummary.providers[:vertex_ai],
              content: response_modifier.response_body
            )

            create_todo(review)
          end

          def create_todo(review)
            TodoService.new.review_submitted(review)
          end
        end
      end
    end
  end
end
