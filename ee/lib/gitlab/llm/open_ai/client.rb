# frozen_string_literal: true

require 'openai'

module Gitlab
  module Llm
    module OpenAi
      class Client
        AI_ROLE = "assistant"
        SYSTEM_ROLE = "system"
        DEFAULT_ROLE = "user"
        DEFAULT_TEMPERATURE = 0.7
        DEFAULT_MAX_TOKENS = 16
        GPT_ROLES = [
          DEFAULT_ROLE,
          SYSTEM_ROLE,
          AI_ROLE
        ].freeze
        DEFAULT_MODELS = {
          chat: "gpt-3.5-turbo",
          completions: "text-davinci-003",
          edits: "text-davinci-edit-001",
          embeddings: "text-embedding-ada-002"
        }.freeze

        include ExponentialBackoff

        def initialize(user)
          @user = user
        end

        def chat(content:, **options)
          return unless enabled?

          messages_chat(
            **{ messages: [{ role: DEFAULT_ROLE, content: content }] }.merge(options)
          )
        end

        # messages: an array with `role` and `content` a keys.
        # the value of `role` should be one of GPT_ROLES
        # this needed to pass back conversation history
        def messages_chat(messages:, **options)
          return unless enabled?

          raise ArgumentError unless messages.all? { |m| GPT_ROLES.member? m[:role] }

          client.chat(
            parameters: {
              model: DEFAULT_MODELS[:chat],
              temperature: DEFAULT_TEMPERATURE,
              messages: messages
            }.merge(options)
          )
        end

        def completions(prompt:, **options)
          return unless enabled?

          client.completions(
            parameters: {
              model: DEFAULT_MODELS[:completions],
              prompt: prompt,
              max_tokens: DEFAULT_MAX_TOKENS
            }.merge(options)
          )
        end

        def edits(input:, instruction:, **options)
          return unless enabled?

          client.edits(
            parameters: {
              model: DEFAULT_MODELS[:edits],
              input: input,
              instruction: instruction
            }.merge(options)
          )
        end

        def embeddings(input:, **options)
          return unless enabled?

          client.embeddings(
            parameters: {
              model: DEFAULT_MODELS[:embeddings],
              input: input
            }.merge(options)
          )
        end

        private

        retry_methods_with_exponential_backoff :chat, :completions, :edits, :embeddings

        attr_reader :user

        def client
          @client ||= OpenAI::Client.new(access_token: access_token)
        end

        def enabled?
          access_token.present? && Feature.enabled?(:openai_experimentation, user)
        end

        def access_token
          @token ||= ::Gitlab::CurrentSettings.openai_api_key
        end
      end
    end
  end
end
