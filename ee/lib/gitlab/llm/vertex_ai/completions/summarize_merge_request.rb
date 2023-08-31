# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      module Completions
        class SummarizeMergeRequest < Gitlab::Llm::Completions::Base
          # rubocop:disable CodeReuse/ActiveRecord
          def execute(user, merge_request, options)
            mr_diff = merge_request.merge_request_diffs.find_by(id: options[:diff_id])

            return unless mr_diff.present?

            response = response_for(user, merge_request, mr_diff)
            response_modifier = ::Gitlab::Llm::VertexAi::ResponseModifiers::Predictions.new(response)

            store_response(response_modifier, mr_diff)
          end
          # rubocop:enable CodeReuse/ActiveRecord

          private

          def response_for(user, merge_request, mr_diff)
            template = ai_prompt_class.new(merge_request, mr_diff)

            ::Gitlab::Llm::VertexAi::Client
              .new(user)
              .text(content: template.to_prompt)
          end

          def store_response(response_modifier, mr_diff)
            return if response_modifier.errors.any?

            MergeRequest::DiffLlmSummary.create!(
              merge_request_diff: mr_diff,
              content: response_modifier.response_body,
              provider: MergeRequest::DiffLlmSummary.providers[:vertex_ai]
            )
          end
        end
      end
    end
  end
end
