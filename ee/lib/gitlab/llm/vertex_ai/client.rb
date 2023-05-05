# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      class Client
        include ::Gitlab::Llm::Concerns::ExponentialBackoff
        DEFAULT_TEMPERATURE = 0.5

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
          {
            instances: [
              {
                messages: [
                  {
                    author: "content",
                    content: content
                  }
                ]
              }
            ],
            parameters: {
              temperature: DEFAULT_TEMPERATURE
            }
          }
        end
      end
    end
  end
end
