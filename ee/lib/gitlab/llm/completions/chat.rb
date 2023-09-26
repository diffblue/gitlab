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
          ai_request = ::Gitlab::Llm::Chain::Requests::Anthropic.new(user, tracking_context: tracking_context)
          context = ::Gitlab::Llm::Chain::GitlabContext.new(
            current_user: user,
            container: resource.try(:resource_parent)&.root_ancestor,
            resource: resource,
            ai_request: ai_request,
            extra_resource: options.delete(:extra_resource) || {}
          )

          chat_response_handler = ::Gitlab::Llm::ChatResponseService.new(context, response_options)

          # This can be removed once all clients use the subscription with the `ai_action: "chat"` parameter.
          # We then can only use `chat_response_handler`.
          # https://gitlab.com/gitlab-org/gitlab/-/issues/423080
          response_handler = ::Gitlab::Llm::ResponseService
            .new(context, response_options.except(:client_subscription_id))

          stream_response_handler = nil
          if response_options[:client_subscription_id]
            stream_response_handler = ::Gitlab::Llm::ResponseService.new(context, response_options)
          end

          response = Gitlab::Llm::Chain::Agents::ZeroShot::Executor.new(
            user_input: options[:content],
            tools: tools(user),
            context: context,
            response_handler: response_handler,
            stream_response_handler: stream_response_handler
          ).execute

          response_modifier = Gitlab::Llm::Chain::ResponseModifier.new(response)

          context.tools_used.each do |tool|
            Gitlab::Tracking.event(
              self.class.to_s,
              'process_gitlab_duo_question',
              label: tool::NAME,
              property: params[:request_id],
              namespace: context.container,
              user: user,
              value: response.status == :ok ? 1 : 0
            )
          end

          response_handler.execute(response: response_modifier)
          chat_response_handler.execute(response: response_modifier)

          response_modifier
        end

        def tools(user)
          tools = TOOLS.dup
          tools << ::Gitlab::Llm::Chain::Tools::EpicIdentifier if Feature.enabled?(:chat_epic_identifier, user)
          tools << ::Gitlab::Llm::Chain::Tools::CiEditorAssistant if Feature.enabled?(:ci_editor_assistant_tool, user)
          tools
        end
      end
    end
  end
end
