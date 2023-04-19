# frozen_string_literal: true

module API
  module Ai
    module Experimentation
      class OpenAi < ::API::Base
        feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned
        urgency :low

        OPEN_AI_API_URL = "https://api.openai.com/v1"
        MODEL_PARAM_DESCRIPTION = <<-DESC
          The OpenAI model name to run the completion against. Please check the OpenAI models overview page
          https://platform.openai.com/docs/models/overview to chose the right model, depeinding on costs, level
          of experimentation, endpoint etc.
        DESC
        before do
          authenticate!
          check_feature_enabled!
        end

        helpers ::API::Helpers::AiHelper
        helpers do
          def open_ai_post(endpoint, json_body: nil)
            url = "#{OPEN_AI_API_URL}/#{endpoint}"

            headers = {
              'Authorization' => ["Bearer #{::Gitlab::CurrentSettings.openai_api_key}"],
              "Content-Type" => ["application/json"]
            }

            workhorse_headers =
              Gitlab::Workhorse.send_url(url, body: json_body.to_json, headers: headers, method: "POST")

            header(*workhorse_headers)

            status :ok
            body ''
          end
        end

        namespace 'ai/experimentation/openai' do
          desc 'Proxies request to OpenAi completions endpoint'
          params do
            requires :prompt, type: String
            requires :model, type: String, desc: MODEL_PARAM_DESCRIPTION
            optional :max_tokens, type: Integer
            optional :temperature, type: Float, values: 0.0..2.0, default: 1.0
            optional :top_p, type: Float
            optional :n, type: Integer
            optional :stream, type: Boolean, default: false
            optional :logprobs, type: Integer, values: 1..5
            optional :echo, type: Boolean, default: false
            optional :presence_penalty, type: Float, values: -2.0..2.0, default: 0
            optional :frequency_penalty, type: Float, values: -2.0..2.0, default: 0
            optional :best_of, type: Integer, default: 1
            optional :user, type: String
          end
          post 'completions' do
            open_ai_post('completions', json_body: declared(params, include_missing: false))
          end

          desc 'Proxies request to OpenAi embeddings endpoint'
          params do
            requires :input, type: String
            requires :model, type: String, desc: MODEL_PARAM_DESCRIPTION
            optional :user, type: String
          end
          post 'embeddings' do
            open_ai_post('embeddings', json_body: declared(params, include_missing: false))
          end

          desc 'Proxies request to OpenAi chat/completion endpoint'
          params do
            requires :messages, type: Array
            requires :model, type: String, desc: MODEL_PARAM_DESCRIPTION
            optional :temperature, type: Float, values: 0.0..2.0, default: 1.0
            optional :top_p, type: Float
            optional :n, type: Integer
            optional :stream, type: Boolean, default: false
            optional :max_tokens, type: Integer
            optional :presence_penalty, type: Float, values: -2.0..2.0, default: 0
            optional :frequency_penalty, type: Float, values: -2.0..2.0, default: 0
            optional :user, type: String
          end
          post 'chat/completions' do
            body open_ai_post(
              'chat/completions', json_body: declared(params, include_missing: false)
            )
          end
        end
      end
    end
  end
end
