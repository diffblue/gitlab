# frozen_string_literal: true

module Mutations
  module Ci
    module Ai
      class GenerateConfig < BaseMutation
        graphql_name 'CiAiGenerateConfig'

        authorize :create_pipeline

        include FindsProject

        argument :project_path,
          GraphQL::Types::ID,
          required: true,
          description: 'Project path for the project related to the open config editor.'

        argument :user_content,
          GraphQL::Types::String,
          required: true,
          description: 'Content of the user message to be sent to the language model.'

        field :user_message,
          Types::Ai::DeprecatedMessageType,
          null: true,
          description: 'User chat message.'

        def resolve(project_path:, user_content:)
          verify_rate_limit!

          project = authorized_find!(project_path)

          response = ::Ci::Llm::AsyncGenerateConfigService.new(
            project: project,
            user: current_user,
            user_content: user_content
          ).execute

          if response.error?
            { user_message: nil, errors: response.errors }
          else
            { user_message: response.payload, errors: [] }
          end
        end

        # TODO: extract to module
        def verify_rate_limit!
          return unless Gitlab::ApplicationRateLimiter.throttled?(:ai_action, scope: [@user])

          raise Gitlab::Graphql::Errors::ResourceNotAvailable,
            'This endpoint has been requested too many times. Try again later.'
        end
      end
    end
  end
end
