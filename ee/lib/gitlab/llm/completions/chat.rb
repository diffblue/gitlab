# frozen_string_literal: true

module Gitlab
  module Llm
    module Completions
      class Chat < Base
        TOOLS = [
          Gitlab::Llm::Chain::Tools::IssueIdentifier,
          Gitlab::Llm::Chain::Tools::SummarizeComments
        ].freeze

        def execute(user, resource, options)
          # The Agent currently only supports Anthropic as it relies on the client's specific methods.
          ai_request = ::Gitlab::Llm::Chain::Requests::Anthropic.new(user)
          context = ::Gitlab::Llm::Chain::GitlabContext.new(
            current_user: user,
            container: resource.try(:resource_parent)&.root_ancestor,
            resource: resource,
            ai_request: ai_request
          )

          response = Gitlab::Llm::Chain::Agents::ZeroShot::Executor.new(
            user_input: options[:content],
            tools: TOOLS,
            context: context
          ).execute

          response_modifier = Gitlab::Llm::Chain::ResponseModifier.new(response)

          ::Gitlab::Llm::GraphqlSubscriptionResponseService
            .new(user, resource, response_modifier, options: { request_id: params[:request_id] })
            .execute
        end
      end
    end
  end
end
