# frozen_string_literal: true

module Gitlab
  module Llm
    module Anthropic
      class Client
        include ::Gitlab::Llm::Concerns::ExponentialBackoff
        include ::Gitlab::Llm::Concerns::EventTracking

        URL = 'https://api.anthropic.com'
        DEFAULT_MODEL = 'claude-2'
        DEFAULT_TEMPERATURE = 0
        DEFAULT_MAX_TOKENS = 2048

        def initialize(user, tracking_context: {})
          @user = user
          @tracking_context = tracking_context
          @logger = Gitlab::Llm::Logger.build
        end

        def complete(prompt:, **options)
          return unless enabled?

          # We do not allow to set `stream` because the separate `#stream` method should be used for streaming.
          # The reason is that streaming the response would not work with the exponential backoff mechanism.
          response = retry_with_exponential_backoff do
            perform_completion_request(prompt: prompt, options: options.except(:stream))
          end

          track_prompt_size(token_size(prompt))
          track_response_size(token_size(response["completion"]))

          response
        end

        def stream(prompt:, **options)
          return unless enabled?

          response_body = ""

          perform_completion_request(prompt: prompt, options: options.merge(stream: true)) do |parsed_event|
            response_body += parsed_event["completion"] if parsed_event["completion"]

            yield parsed_event if block_given?
          end

          track_prompt_size(token_size(prompt))
          track_response_size(token_size(response_body))

          response_body
        end

        private

        attr_reader :user, :logger, :tracking_context

        def perform_completion_request(prompt:, options:)
          logger.info(message: "Performing request to Anthropic", options: options)

          response = Gitlab::HTTP.post(
            URI.join(URL, '/v1/complete'),
            headers: request_headers,
            body: request_body(prompt: prompt, options: options).to_json,
            stream_body: options.fetch(:stream, false)
          ) do |fragment|
            parse_sse_events(fragment).each do |parsed_event|
              yield parsed_event if block_given?
            end
          end

          logger.debug(message: "Received response from Anthropic", response: response)

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

        def token_size(content)
          # Anthropic's APIs don't send used tokens as part of the response, so
          # instead we estimate the number of tokens based on typical token size -
          # one token is roughly 4 chars.
          content.to_s.size / 4
        end

        # Following the SSE spec
        # https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation
        # and using the format from Anthropic: https://docs.anthropic.com/claude/reference/streaming#example
        # we can assume that the JSON we're looking comes after `data: `
        def parse_sse_events(fragment)
          fragment.scan(/(?:data): (\{.*\})/i).flatten.map { |data| Gitlab::Json.parse(data) }
        end
      end
    end
  end
end
