# frozen_string_literal: true

module Gitlab
  module Llm
    module Anthropic
      class Client
        include Gitlab::Llm::Concerns::ExponentialBackoff

        URL = 'https://api.anthropic.com'
        DEFAULT_MODEL = 'claude-v1.3'
        DEFAULT_TEMPERATURE = 0.7
        DEFAULT_MAX_TOKENS = 16

        def initialize(user)
          @user = user
        end

        def complete(prompt:, **options)
          return unless enabled?

          Gitlab::HTTP.post(
            URI.join(URL, '/v1/complete'),
            headers: request_headers,
            body: request_body(prompt: prompt, options: options).to_json
          )
        end

        private

        attr_reader :user

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
