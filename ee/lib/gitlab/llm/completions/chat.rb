# frozen_string_literal: true

module Gitlab
  module Llm
    module Completions
      class Chat < Base
        TOOLS = [Gitlab::Llm::Chain::Tools::IssueIdentifier].freeze

        def execute(user, resource, options)
          # The Agent currently only supports Vertex as it relies on VertexAi::Client specific methods.
          client = ::Gitlab::Llm::VertexAi::Client.new(user)
          context = ::Gitlab::Llm::Chain::GitlabContext.new(
            current_user: user,
            container: resource.resource_parent.root_ancestor,
            resource: resource,
            ai_client: client
          )

          response = Gitlab::Llm::Chain::Agents::ZeroShot.new(
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
