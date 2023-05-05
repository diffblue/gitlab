# frozen_string_literal: true

module Gitlab
  module Llm
    module Tofa
      class Client
        include ::Gitlab::Llm::Concerns::ExponentialBackoff

        def initialize(_user, configuration = Configuration.new)
          @configuration = configuration
        end

        def chat(content:, **options)
          HTTParty.post( # rubocop: disable Gitlab/HTTParty
            url,
            headers: headers,
            body: default_payload_for(content).merge(options).to_json
          )
        end

        private

        retry_methods_with_exponential_backoff :chat

        attr_reader :configuration

        delegate(
          :access_token,
          :host,
          :tofa_request_json_keys,
          :tofa_request_payload,
          :url,
          to: :configuration
        )

        def headers
          {
            "Accept" => "application/json",
            "Authorization" => "Bearer #{access_token}",
            "Host" => host,
            "Content-Type" => "application/json"
          }
        end

        def default_payload_for(content)
          json = JSON.parse(tofa_request_payload) # rubocop: disable Gitlab/Json
          json_keys = tofa_request_json_keys.split(' ')
          json[json_keys[0]][0][json_keys[1]][0][json_keys[2]] = content

          json
        end
      end
    end
  end
end
