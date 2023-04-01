# frozen_string_literal: true

module API
  module Ai
    module Experimentation
      class OpenAi < ::API::Base
        feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned
        urgency :low

        OPEN_AI_API_URL = "https://api.openai.com/v1"

        before do
          authenticate!
          check_feature_enabled
        end

        helpers do
          def check_feature_enabled
            not_found!('REST API endpoint not found') unless Feature.enabled?(:openai_experimentation, current_user)
          end

          def open_ai_post(endpoint, json_body: nil)
            url = "#{OPEN_AI_API_URL}/#{endpoint}"

            header = { 'Authorization' => "Bearer #{::Gitlab::CurrentSettings.openai_api_key}",
                       "Content-Type" => "application/json" }
            response = Gitlab::HTTP.post(url, headers: header, body: Gitlab::Json.dump(json_body))
            response_body = Gitlab::Json.parse(response.body, symbolize_names: true)

            body response_body

          rescue Gitlab::HTTP::Error, StandardError => error
            Gitlab::AppLogger.info("#{self.class.name}: Error while connecting to OpenAI: #{error.message}")
          end
        end

        namespace 'ai/experimentation/openai' do
          desc 'Proxies request to OpenAi completions endpoint'
          params do
            requires :prompt, type: String, desc: ''
            optional :model, type: String, desc: '', default: 'text-davinci-003'
            optional :max_tokens, type: Integer, desc: '', default: 16
            optional :temperature, type: Float, desc: ''
            optional :top_p, type: Float, desc: ''
            optional :n, type: Integer, desc: ''
            optional :stream, type: Boolean, desc: '', default: false
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
            requires :input, type: String, desc: ''
            optional :model, type: String, desc: '', default: 'text-davinci-003'
            optional :user, type: String
          end
          post 'embeddings' do
            open_ai_post('embeddings', json_body: declared(params, include_missing: false))
          end
        end
      end
    end
  end
end
