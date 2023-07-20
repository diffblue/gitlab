# frozen_string_literal: true

module Gitlab
  module Llm
    module Anthropic
      class Client
        include Gitlab::Llm::Concerns::ExponentialBackoff

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

          logger.debug(message: "Performing request to Anthropic", options: options)

          response = Gitlab::HTTP.post(
            URI.join(URL, '/v1/complete'),
            headers: request_headers,
            body: request_body(prompt: prompt, options: options).to_json
          )

          logger.debug(message: "Received response from Anthropic", response: response)

          response
        end

        private

        attr_reader :user, :logger

        retry_methods_with_exponential_backoff :complete

        def enabled?
          api_key.present?
        end

        def api_key
          @api_key ||= ::Gitlab::CurrentSettings.anthropic_api_key
        end

        def request_headers
          {
            'Accept' => 'application/json',
            'Content-Type' => 'application/json',
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
      end
    end
  end
end
