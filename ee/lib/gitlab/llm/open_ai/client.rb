# frozen_string_literal: true

require 'openai'

module Gitlab
  module Llm
    module OpenAi
      class Client
        include ::Gitlab::Llm::Concerns::ExponentialBackoff

        InputModerationError = Class.new(StandardError)

        def initialize(user, request_timeout: nil)
          @user = user
          @request_timeout = request_timeout
        end

        def chat(content:, moderated: true, **options)
          request(
            endpoint: :chat,
            moderated: moderated,
            parameters: Options.new.chat(content: content, **options)
          )
        end

        # messages: an array with `role` and `content` a keys.
        # the value of `role` should be one of GPT_ROLES
        # this needed to pass back conversation history
        def messages_chat(messages:, moderated: true, **options)
          request(
            endpoint: :chat,
            moderated: moderated,
            parameters: Options.new.messages_chat(messages: messages, **options)
          )
        end

        def completions(prompt:, moderated: true, **options)
          request(
            endpoint: :completions,
            moderated: moderated,
            parameters: Options.new.completions(prompt: prompt, **options)
          )
        end

        def edits(input:, instruction:, moderated: true, **options)
          request(
            endpoint: :edits,
            moderated: moderated,
            parameters: Options.new.edits(input: input, instruction: instruction, **options)
          )
        end

        def embeddings(input:, moderated: false, **options)
          request(
            endpoint: :embeddings,
            moderated: moderated,
            parameters: Options.new.embeddings(input: input, **options)
          )
        end

        def moderations(input:, **options)
          request(
            endpoint: :moderations,
            moderated: false,
            parameters: Options.new.moderations(input: input, **options)
          )
        end

        private

        retry_methods_with_exponential_backoff :chat, :completions, :edits, :embeddings, :moderations

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

        def request(endpoint:, moderated:, **options)
          return unless enabled?

          moderate_input!(moderation_input(endpoint, options)) if moderated

          response = client.public_send(endpoint, **options) # rubocop:disable GitlabSecurity/PublicSend

          track_cost(endpoint, response.parsed_response&.dig('usage'))

          response
        end

        def track_cost(endpoint, usage_data)
          return unless usage_data

          track_cost_metric("#{endpoint}/prompt", usage_data['prompt_tokens'])
          track_cost_metric("#{endpoint}/completion", usage_data['completion_tokens'])
        end

        def track_cost_metric(context, amount)
          return unless amount

          cost_metric.increment(
            {
              vendor: 'open_ai',
              item: context,
              unit: 'tokens',
              feature_category: ::Gitlab::ApplicationContext.current_context_attribute(:feature_category)
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

        def moderate_input!(input)
          return if Feature.disabled?(:openai_moderation)

          flagged = moderations(input: input)
            .parsed_response
            &.dig('results')
            &.any? { |r| r['flagged'] }

          raise(InputModerationError, "Provided input violates OpenAI's Content Policy") if flagged
        end

        def moderation_input(endpoint, options)
          case endpoint
          when :chat
            options.dig(:parameters, :messages).pluck(:content) # rubocop:disable CodeReuse/ActiveRecord
          when :completions
            options.dig(:parameters, :prompt)
          when :edits, :embeddings
            options.dig(:parameters, :input)
          end
        end
      end
    end
  end
end
