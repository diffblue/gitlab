# frozen_string_literal: true

module Ci
  module Llm
    class AsyncGenerateConfigService
      include ::Services::ReturnServiceResponses
      include Gitlab::Utils::StrongMemoize
      include ::Gitlab::ExclusiveLeaseHelpers

      # TODO move to a seperate file
      TOTAL_MODEL_TOKEN_LIMIT = 4096
      MAX_RESPONSE_TOKENS = (TOTAL_MODEL_TOKEN_LIMIT / 2.5).to_i

      INPUT_TOKEN_LIMIT = 500
      INPUT_CHAR_LIMIT = INPUT_TOKEN_LIMIT * 4

      NOT_FOUND = { message: 'Not Found', reason: :not_found }.freeze

      def initialize(project:, user:, user_content:)
        @project = project
        @user = user
        @user_content = user_content
        @fetch_iterations = 0
      end

      def execute
        return error(message: 'Project not found', reason: :not_found) unless @project
        return error(**NOT_FOUND) unless @user.can?(:create_pipeline, @project)
        return error(message: 'Feature not available', reason: :not_found) unless enabled?
        return error(message: 'User content is too large', reason: :content_size) if content_too_big?

        # Prevent concurrent updates to the same conversation
        in_lock(lock_key, ttl: 10.seconds, retries: 0) do
          perform_work
        end
      rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
        error(message: 'Request is already being processed')
      end

      private

      def perform_work
        # The frontend needs the user message from the mutation for polling
        user_message, ai_message = persist_messages

        sidekiq_job_id = ::Ci::Llm::GenerateConfigWorker.perform_async(ai_message.id)

        if sidekiq_job_id
          track_snowplow_event('success')
          return success(user_message)
        end

        error(message: 'Request is already being processed')
      end

      def lock_key
        "#{self.class.name.underscore}:#{@project.id}:#{@user.id}"
      end

      def persist_messages
        user_message = nil
        ai_message = nil
        # Use a transaction to ensure a user message is never persisted without an ai response
        Ci::Editor::AiConversation::Message.transaction do
          user_message = create_message(
            role: Gitlab::Llm::OpenAi::Options::DEFAULT_ROLE,
            content: @user_content
          )

          ai_message = create_message(
            role: Gitlab::Llm::OpenAi::Options::AI_ROLE,
            content: nil
          )
        end

        [user_message, ai_message]
      end

      def create_message(role:, content:)
        Ci::Editor::AiConversation::Message.create(
          project_id: @project.id,
          user_id: @user.id,
          role: role,
          content: content
        )
      end

      def enabled?
        Ai::Project::Conversations.new(@project, @user).ci_config_chat_enabled?
      end

      def content_too_big?
        @user_content.size > INPUT_CHAR_LIMIT
      end

      # TODO extract to module
      def track_snowplow_event(property)
        Gitlab::Tracking.event(
          self.class.to_s,
          "execute_llm_method",
          label: 'generate_config',
          property: property,
          user: @user,
          project: @project,
          namespace: @project.namespace
        )
      end

      def error(options = {})
        track_snowplow_event('error')
        ServiceResponse.error(**options)
      end

      def success(user_message)
        ServiceResponse.success(payload: user_message)
      end
    end
  end
end
