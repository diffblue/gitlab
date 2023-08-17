# frozen_string_literal: true

module Gitlab
  module Llm
    module Completions
      class Chat < Base
        TOOLS = [
          ::Gitlab::Llm::Chain::Tools::JsonReader,
          ::Gitlab::Llm::Chain::Tools::IssueIdentifier,
          ::Gitlab::Llm::Chain::Tools::GitlabDocumentation
        ].freeze

        def execute(user, resource, options)
          # we should be able to switch between different providers that we know agent supports, by initializing the
          # one we like. At the moment Anthropic is default and some features may not be supported
          # by other providers.
          ai_request = ::Gitlab::Llm::Chain::Requests::Anthropic.new(user)
          context = ::Gitlab::Llm::Chain::GitlabContext.new(
            current_user: user,
            container: resource.try(:resource_parent)&.root_ancestor,
            resource: resource,
            ai_request: ai_request
          )

          response = Gitlab::Llm::Chain::Agents::ZeroShot::Executor.new(
            user_input: options[:content],
            tools: tools(user),
            context: context
          ).execute

          Gitlab::Metrics::Sli::Apdex[:llm_chat_answers].increment(
            labels: { tool: response.last_tool_name || :unknown },
            success: response.status == :ok
          )

          response_modifier = Gitlab::Llm::Chain::ResponseModifier.new(response)

          ::Gitlab::Llm::GraphqlSubscriptionResponseService
            .new(user, resource, response_modifier, options: response_options)
            .execute
        end

        def tools(user)
          tools = TOOLS.dup
          tools << ::Gitlab::Llm::Chain::Tools::EpicIdentifier if Feature.enabled?(:chat_epic_identifier, user)
          tools
        end
      end
    end
  end
end
