# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      class Client
        include ::Gitlab::Llm::Concerns::ExponentialBackoff
        include ::Gitlab::Llm::Concerns::MeasuredRequest
        extend ::Gitlab::Utils::Override

        def initialize(_user, client_options = {})
          @logger = Gitlab::Llm::Logger.build
          @client_options = client_options
        end

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

        # @param [Array<Hash>] content - Input hash with `prefix` and `suffix` keys
        #   - Use the suffix to generate code in the middle of existing code.
        #   - The model will try to generate code from the prefix to the suffix.
        # @param [Hash] options - Additional options to pass to the request
        def code_completion(content:, **options)
          request(
            content: content,
            config: Configuration.new(
              model_config: ModelConfigurations::CodeCompletion.new
            ),
            **options
          )
        end

        private

        attr_reader :logger

        retry_methods_with_exponential_backoff :chat, :text, :code, :messages_chat, :code_completion

        def request(content:, config:, **options)
          logger.info(message: "Performing request to Vertex", config: config)

          response = Gitlab::HTTP.post(
            config.url,
            headers: config.headers,
            body: config.payload(content).merge(options).to_json,
            stream_body: true
          )

          logger.debug(message: "Received response from Vertex", response: response)
          increment_metric(client: :vertex_ai, response: response)

          response
        rescue StandardError => e
          increment_metric(client: :vertex_ai)
          raise e
        end

        def service_name
          'vertex_ai'
        end

        override :retry_immediately?
        def retry_immediately?(response)
          return unless @client_options[:retry_content_blocked_requests]

          content_blocked?(response)
        end

        def content_blocked?(response)
          response.parsed_response.with_indifferent_access.dig("safetyAttributes", "blocked")
        end
      end
    end
  end
end
