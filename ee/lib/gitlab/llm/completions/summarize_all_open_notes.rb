# frozen_string_literal: true

module Gitlab
  module Llm
    module Completions
      class SummarizeAllOpenNotes < Gitlab::Llm::Completions::Base
        def execute(user, issuable, options = {})
          return unless user
          return unless issuable

          context = ::Gitlab::Llm::Chain::GitlabContext.new(
            current_user: user,
            container: issuable.resource_parent,
            resource: issuable,
            ai_request: ai_provider_request(user, options)
          )

          answer = ::Gitlab::Llm::Chain::Tools::SummarizeComments::Executor.new(
            context: context, options: { raw_ai_response: true }
          ).execute
          response_modifier = Gitlab::Llm::ResponseModifiers::ToolAnswer.new({ content: answer.content }.to_json)

          ::Gitlab::Llm::GraphqlSubscriptionResponseService.new(
            user, issuable, response_modifier, options: response_options
          ).execute
        end

        private

        def ai_provider_request(user, options)
          case options[:ai_provider].to_s
          when 'anthropic'
            ::Gitlab::Llm::Chain::Requests::Anthropic.new(user)
          when 'vertex_ai'
            ::Gitlab::Llm::Chain::Requests::VertexAi.new(user)
          when 'open_ai'
            ::Gitlab::Llm::Chain::Requests::OpenAi.new(user)
          else
            raise "unknown ai_provider #{options[:ai_provider]}"
          end
        end
      end
    end
  end
end
