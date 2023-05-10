# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      class Client
        include ::Gitlab::Llm::Concerns::ExponentialBackoff

        def initialize(_user); end

        # @param [String] content - Input string
        # @param [Hash] options - Additional options to pass to the request
        def chat(content:, **options)
          request(
            content: content,
            config: Configuration.new(
              model_config: ModelConfigurations::CodeChat.new
            ),
            **options
          )
        end

        # Multi-turn chat with conversational history in a structured alternate-author form.
        #
        # @param [Array<Hash>] content - Array of hashes with `author` and `content` keys
        #   - First and last message should have "author": "user"
        #   - Model responses should have "author": "content"
        #   - Messages appear in chronological order: oldest first, newest last
        # @param [Hash] options - Additional options to pass to the request
        def messages_chat(content:, **options)
          request(
            content: content,
            config: Configuration.new(
              model_config: ModelConfigurations::Chat.new
            ),
            **options
          )
        end

        # @param [String] content - Input string
        # @param [Hash] options - Additional options to pass to the request
        def text(content:, **options)
          request(
            content: content,
            config: Configuration.new(
              model_config: ModelConfigurations::Text.new
            ),
            **options
          )
        end

        # @param [String] content - Input string
        # @param [Hash] options - Additional options to pass to the request
        def code(content:, **options)
          request(
            content: content,
            config: Configuration.new(
              model_config: ModelConfigurations::Code.new
            ),
            **options
          )
        end

        private

        retry_methods_with_exponential_backoff :chat, :text, :code, :messages_chat

        def request(content:, config:, **options)
          HTTParty.post( # rubocop: disable Gitlab/HTTParty
            config.url,
            headers: config.headers,
            body: config.payload(content).merge(options).to_json
          )
        end
      end
    end
  end
end
