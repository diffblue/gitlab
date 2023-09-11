# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      class Client
        include ::Gitlab::Llm::Concerns::ExponentialBackoff
        include ::Gitlab::Llm::Concerns::EventTracking
        extend ::Gitlab::Utils::Override

        def initialize(user, retry_content_blocked_requests: false, tracking_context: {})
          @logger = Gitlab::Llm::Logger.build
          @retry_content_blocked_requests = retry_content_blocked_requests
          @user = user
          @tracking_context = tracking_context
        end

        # @param [String] content - Input string
        # @param [Hash] options - Additional options to pass to the request
        def chat(content:, **options)
          track_prompt_size(token_size(content))

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
          track_prompt_size(token_size(content.reduce("") { |acc, m| acc + m[:content] }))

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
          track_prompt_size(token_size(content))

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
          track_prompt_size(token_size(content))

          request(
            content: content,
            config: Configuration.new(
              model_config: ModelConfigurations::Code.new
            ),
            **options
          )
        end

        # @param [Hash] content - Input hash with `prefix` and `suffix` keys
        #   - Use the suffix to generate code in the middle of existing code.
        #   - The model will try to generate code from the prefix to the suffix.
        # @param [Hash] options - Additional options to pass to the request
        def code_completion(content:, **options)
          track_prompt_size(token_size([content[:prefix], content[:suffix]].join('')))

          request(
            content: content,
            config: Configuration.new(
              model_config: ModelConfigurations::CodeCompletion.new
            ),
            **options
          )
        end

        # @param [String] content - Input string
        # @param [Hash] options - Additional options to pass to the request
        def text_embeddings(content:, **options)
          track_prompt_size(token_size(content))

          request(
            content: content,
            config: Configuration.new(
              model_config: ModelConfigurations::TextEmbeddings.new
            ),
            **options
          )
        end

        private

        attr_reader :logger, :tracking_context, :user, :retry_content_blocked_requests

        def request(content:, config:, **options)
          logger.info(message: "Performing request to Vertex", config: config)

          response = retry_with_exponential_backoff do
            Gitlab::HTTP.post(
              config.url,
              headers: config.headers,
              body: config.payload(content).merge(options).to_json,
              stream_body: true
            )
          end

          logger.debug(message: "Received response from Vertex", response: response)

          content = Gitlab::Llm::VertexAi::ResponseModifiers::Predictions.new(response).response_body
          track_response_size(token_size(content))

          response
        end

        def service_name
          'vertex_ai'
        end

        override :retry_immediately?
        def retry_immediately?(response)
          return unless retry_content_blocked_requests

          content_blocked?(response)
        end

        def content_blocked?(response)
          response.parsed_response.with_indifferent_access.dig("safetyAttributes", "blocked")
        end

        def token_size(content)
          # Vertex APIs don't send used tokens as part of the response, so
          # instead we estimate the number of tokens based on typical token size -
          # one token is roughly 4 chars.
          content.to_s.size / 4
        end
      end
    end
  end
end
