# frozen_string_literal: true

module API
  module Ai
    module Experimentation
      class Anthropic < ::API::Base
        feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned
        urgency :low

        MODEL_PARAM_DESCRIPTION = <<-DESC
          The Anthropic model name to run the completion against. Please check the Anthropic model parameter
          https://console.anthropic.com/docs/api/reference#parameters to chose the right model, depending on
          costs, level of experimentation, endpoint etc.
        DESC

        before do
          authenticate!
          check_feature_enabled
        end

        helpers do
          def check_feature_enabled
            not_found!('REST API endpoint not found') unless Feature.enabled?(:anthropic_experimentation) &&
              Feature.enabled?(:ai_experimentation_api, current_user)
          end

          def anthropic_post(endpoint, json_body: nil)
            url = URI.join(Gitlab::Llm::Anthropic::Client::URL, endpoint).to_s

            headers = {
              "Accept" => ["application/json"],
              "Content-Type" => ["application/json"],
              "X-Api-Key" => [anthropic_api_key]
            }

            workhorse_headers =
              Gitlab::Workhorse.send_url(url, body: json_body.to_json, headers: headers, method: "POST")

            header(*workhorse_headers)

            status :ok
            body ''
          end

          def anthropic_api_key
            ::Gitlab::CurrentSettings.anthropic_api_key
          end
        end

        namespace 'ai/experimentation/anthropic' do
          desc 'Proxies request to Anthropic complete endpoint'
          params do
            requires :prompt, type: String
            requires :model, type: String, desc: MODEL_PARAM_DESCRIPTION
            requires :max_tokens_to_sample,
              type: Integer,
              default: Gitlab::Llm::Anthropic::Client::DEFAULT_MAX_TOKENS
            optional :stop_sequences, type: Array
            optional :stream, type: Boolean, default: false
            optional :temperature,
              type: Float,
              values: 0.0..1.0,
              default: Gitlab::Llm::Anthropic::Client::DEFAULT_TEMPERATURE
            optional :top_k, type: Float, default: -1
            optional :top_p, type: Float, default: -1
          end
          post 'complete' do
            body anthropic_post(
              'v1/complete', json_body: declared(params, include_missing: false)
            )
          end
        end
      end
    end
  end
end
