# frozen_string_literal: true

module Ci
  module Llm
    # This class sends the conversation history to the an AI service
    # and stores the response. It is expected to be executed by an async job
    # and should not be executed alone as it dosn't have permission checks
    class GenerateConfigService
      include ::Services::ReturnServiceResponses
      include Gitlab::Utils::StrongMemoize

      AiFetchError = Class.new(StandardError)

      TOTAL_MODEL_TOKEN_LIMIT = 4096

      def initialize(ai_message:)
        @ai_message = ai_message
        @project = ai_message&.project
        @user = ai_message&.user
        @fetch_iterations = 0
      end

      def execute
        return unless @project && @user

        response = fetch

        update_with_ai(response.content)
      rescue StandardError => e
        raise e
      end

      private

      def fetch
        delete_first_message_pair while all_content_too_big?

        response_json = client.messages_chat(
          messages: request_messages,
          # Low temperature for a low-creativity transformation tasks
          temperature: 0.3
        )

        response = Gitlab::Llm::OpenAiChatResponse.new(response_json)

        # if the request is too long then delete some persisted content and re-fetch
        # TODO: remove once tokens are properly calculated with tiktoken_ruby
        if response.error_code == 'context_length_exceeded'
          delete_first_message_pair
          @fetch_iterations += 1
          return if @fetch_iterations >= 4

          sleep 0.5
          fetch
        end

        raise AiFetchError, response.error_message if response.error_code

        unless response.finish_reason == 'stop' || response.finish_reason == 'length'
          raise AiFetchError,
            response.finish_reason
        end

        response
      end

      def request_messages
        [
          {
            role: Gitlab::Llm::OpenAi::Options::SYSTEM_ROLE,
            content: gitlab_prompt
          },
          *stored_message_history
        ].filter { |msg| msg[:content].present? }
      end

      def update_with_ai(ai_content)
        # raise an error which triggers a retry of the service if no ai_content was generated
        raise AiFetchError unless ai_content

        @ai_message.update!(content: ai_content)
      end

      def stored_message_history
        Ci::Editor::AiConversation::Message
          .belonging_to(@project, @user)
          .asc
          .map do |m|
            {
              role: m.role,
              content: m.content
            }
          end
      end

      def all_content_too_big?
        # multiply times 3.9 because 1 token ~= 4 chars in English
        # Using a number slightly lower than 4 gives us a bit of wiggle room
        request_messages.reduce(0) { |sum, msg| sum + msg[:content].size } > TOTAL_MODEL_TOKEN_LIMIT * 3.9
      end

      def delete_first_message_pair
        Ci::Editor::AiConversation::Message.transaction do
          Ci::Editor::AiConversation::Message.first_pair(@project, @user).delete_all
        end
      end

      def gitlab_prompt
        "You are an ai assistant talking to a devops or software engineer. " \
          "you should coach users to create a gitlab-ci.yaml file " \
          "which can be used to create a GitLab pipeline. " \
          "Please provide example yaml assuming a single yaml file will be used. " \
          "Please include yaml style commenting to describe what the configuration will do."
      end

      def client
        Gitlab::Llm::OpenAi::Client.new(@user)
      end
      strong_memoize_attr :client

      def success
        ServiceResponse.success
      end
    end
  end
end
