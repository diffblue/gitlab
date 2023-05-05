# frozen_string_literal: true

module API
  module Ai
    module Experimentation
      class VertexAi < ::API::Base
        feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned
        urgency :low

        before do
          authenticate!
          check_feature_enabled
        end

        helpers do
          def check_feature_enabled
            not_found!('REST API endpoint not found') unless Feature.enabled?(:tofa_experimentation_main_flag) &&
              Feature.enabled?(:ai_experimentation_api, current_user)
          end

          def vertex_ai_post(_endpoint, json_body: nil)
            headers = {
              "Accept" => ["application/json"],
              "Authorization" => ["Bearer #{tofa_api_token}"],
              "Host" => [host],
              "Content-Type" => ["application/json"]
            }

            workhorse_headers =
              Gitlab::Workhorse.send_url(url, body: json_body.to_json, headers: headers, method: "POST")

            header(*workhorse_headers)

            status :ok
            body ''
          end

          def default_payload_for(params)
            tofa_params = params.transform_keys { |name| name.camelize(:lower) }
            content = tofa_params.delete(:content)
            json = {
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
                temperature: ::Gitlab::Llm::VertexAi::Client::DEFAULT_TEMPERATURE
              }
            }

            json[:parameters].merge!(tofa_params)
            json
          end

          def configuration
            @configuration ||= Gitlab::Llm::VertexAi::Configuration.new
          end

          def tofa_api_token
            if !Rails.env.production? && ENV.fetch('TOFA_ACCESS_TOKEN', nil)
              ENV.fetch('TOFA_ACCESS_TOKEN')
            else
              configuration.access_token
            end
          end

          delegate(
            :host,
            :url,
            to: :configuration
          )
        end

        namespace 'ai/experimentation/tofa' do
          desc 'Proxies request to Vertex AI chat endpoint'
          params do
            requires :content, type: String
            optional :temperature, type: Float, values: 0.0..1.0, default: 0.5
            optional :max_output_tokens, type: Integer, values: 1..1024, default: 256
            optional :top_k, type: Integer, values: 1..40, default: 40
            optional :top_p, type: Float, values: 0.0..1.0, default: 0.95
          end
          post 'chat' do
            body vertex_ai_post(
              'chat', json_body: default_payload_for(declared(params, include_missing: false))
            )
          end
        end
      end
    end
  end
end
