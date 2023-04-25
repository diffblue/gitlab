# frozen_string_literal: true

require 'openai'

module Gitlab
  module Llm
    module OpenAi
      class Client
        DEFAULT_ROLE = "user"
        DEFAULT_TEMPERATURE = 0.7
        DEFAULT_MAX_TOKENS = 16
        DEFAULT_MODELS = {
          chat: "gpt-3.5-turbo",
          completions: "text-davinci-003",
          edits: "text-davinci-edit-001",
          embeddings: "text-embedding-ada-002"
        }.freeze

        include ExponentialBackoff

        def initialize(user, request_timeout: nil)
          @user = user
          @request_timeout = request_timeout
        end

        def chat(content:, **options)
          return unless enabled?

          client.chat(
            parameters: {
              model: DEFAULT_MODELS[:chat],
              messages: [{ role: DEFAULT_ROLE, content: content }],
              temperature: DEFAULT_TEMPERATURE
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

        attr_reader :user, :request_timeout

        def client
          @client ||= OpenAI::Client.new(access_token: access_token, request_timeout: request_timeout)
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
