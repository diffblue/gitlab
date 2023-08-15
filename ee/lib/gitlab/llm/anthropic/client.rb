# frozen_string_literal: true

module Gitlab
  module Llm
    module Anthropic
      class Client
        include ::Gitlab::Llm::Concerns::ExponentialBackoff
        include ::Gitlab::Llm::Concerns::MeasuredRequest

        URL = 'https://api.anthropic.com'
        DEFAULT_MODEL = 'claude-2'
        DEFAULT_TEMPERATURE = 0
        DEFAULT_MAX_TOKENS = 2048

        def initialize(user)
          @user = user
          @logger = Gitlab::Llm::Logger.build
        end

        def complete(prompt:, **options)
          return unless enabled?

          # We do not allow to set `stream` because the separate `#stream` method should be used for streaming.
          # The reason is that streaming the response would not work with the exponential backoff mechanism.
          perform_completion_request(prompt: prompt, options: options.except(:stream))
        rescue StandardError => e
          increment_metric(client: :anthropic)
          raise e
        end

        def stream(prompt:, **options)
          return unless enabled?

          perform_completion_request(prompt: prompt, options: options.merge(stream: true)) do |fragment|
            yield parse_sse_event(fragment) if block_given?
          end
        rescue StandardError => e
          increment_metric(client: :anthropic)
          raise e
        end

        private

        attr_reader :user, :logger

        retry_methods_with_exponential_backoff :complete

        def perform_completion_request(prompt:, options:)
          logger.info(message: "Performing request to Anthropic", options: options)

          response = Gitlab::HTTP.post(
            URI.join(URL, '/v1/complete'),
            headers: request_headers,
            body: request_body(prompt: prompt, options: options).to_json,
            stream_body: options.fetch(:stream, false)
          ) do |fragment|
            yield fragment if block_given?
          end

          logger.debug(message: "Received response from Anthropic", response: response)

          increment_metric(client: :anthropic, response: response)

          response
        end

        def enabled?
          api_key.present?
        end

        def api_key
          @api_key ||= ::Gitlab::CurrentSettings.anthropic_api_key
        end

        # We specificy the `anthropic-version` header to receive the stream word by word instead of the accumulated
        # response https://docs.anthropic.com/claude/reference/streaming.
        def request_headers
          {
            'Accept' => 'application/json',
            'Content-Type' => 'application/json',
            'anthropic-version' => '2023-06-01',
            'x-api-key' => api_key
          }
        end

        def request_body(prompt:, options: {})
          {
            prompt: prompt,
            model: DEFAULT_MODEL,
            max_tokens_to_sample: DEFAULT_MAX_TOKENS,
            temperature: DEFAULT_TEMPERATURE
          }.merge(options)
        end

        # Following the SSE spec
        # https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation
        # and using the format from Anthropic: https://docs.anthropic.com/claude/reference/streaming#example
        # we can assume that the JSON we're looking comes after `data: `
        def parse_sse_event(fragment)
          Gitlab::Json.parse(fragment.split('data: ').last)
        end
      end
    end
  end
end
