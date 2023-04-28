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

        def initialize(user, request_timeout: nil)
          @user = user
          @request_timeout = request_timeout
        end

        def chat(content:, **options)
          messages_chat(
            **{ messages: [{ role: DEFAULT_ROLE, content: content }] }.merge(options)
          )
        end

        # messages: an array with `role` and `content` a keys.
        # the value of `role` should be one of GPT_ROLES
        # this needed to pass back conversation history
        def messages_chat(messages:, **options)
          raise ArgumentError unless messages.all? { |m| GPT_ROLES.member? m.with_indifferent_access[:role] }

          request(
            :chat,
            parameters: {
              model: DEFAULT_MODELS[:chat],
              temperature: DEFAULT_TEMPERATURE,
              messages: messages
            }.merge(options)
          )
        end

        def completions(prompt:, **options)
          request(
            :completions,
            parameters: {
              model: DEFAULT_MODELS[:completions],
              prompt: prompt,
              max_tokens: DEFAULT_MAX_TOKENS
            }.merge(options)
          )
        end

        def edits(input:, instruction:, **options)
          request(
            :edits,
            parameters: {
              model: DEFAULT_MODELS[:edits],
              input: input,
              instruction: instruction
            }.merge(options)
          )
        end

        def embeddings(input:, **options)
          request(
            :embeddings,
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

        def request(endpoint, options)
          return unless enabled?

          response = client.public_send(endpoint, **options) # rubocop:disable GitlabSecurity/PublicSend

          track_cost(
            usage_data: response.parsed_response&.dig('usage'),
            model: response.parsed_response&.dig('model')
          )

          response
        end

        def track_cost(usage_data:, model:)
          return unless usage_data

          track_cost_metric("#{model}/prompt", usage_data['prompt_tokens'])
          track_cost_metric("#{model}/completion", usage_data['completion_tokens'])
        end

        def track_cost_metric(context, amount)
          return unless amount

          cost_metric.increment(
            {
              vendor: 'open_ai',
              item: context,
              unit: 'tokens'
            },
            amount
          )
        end

        def cost_metric
          @cost_metric ||= Gitlab::Metrics.counter(
            :gitlab_cloud_cost_spend_entry_total,
            'Number of units spent per vendor entry'
          )
        end
      end
    end
  end
end
