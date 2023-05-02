# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      class Workhorse
        OPEN_AI_API_URL = "https://api.openai.com/v1"
        CHAT_URL = "#{OPEN_AI_API_URL}/chat/completions".freeze

        class << self
          def default_headers
            {
              'Authorization' => ["Bearer #{::Gitlab::CurrentSettings.openai_api_key}"],
              'Content-Type' => ['application/json']
            }
          end

          def chat_response(options:)
            Gitlab::Workhorse.send_url(CHAT_URL,
              body: options.to_json, headers: default_headers, method: "POST")
          end
        end
      end
    end
  end
end
