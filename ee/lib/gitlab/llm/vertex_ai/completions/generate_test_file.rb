# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      module Completions
        class GenerateTestFile < Gitlab::Llm::Completions::Base
          DEFAULT_ERROR = 'An unexpected error has occurred.'

          def execute(user, merge_request, options)
            unless vertex_ai?(merge_request)
              return ::Gitlab::Llm::OpenAi::Completions::GenerateTestFile
                .new(ai_prompt_class)
                .execute(user, merge_request, options)
            end

            response = response_for(user, merge_request, options[:file_path])
            response_modifier = ::Gitlab::Llm::VertexAi::ResponseModifiers::Predictions.new(response)

            ::Gitlab::Llm::GraphqlSubscriptionResponseService.new(
              user, merge_request, response_modifier, options: options
            ).execute
          rescue StandardError => error
            Gitlab::ErrorTracking.track_exception(error)

            response_modifier = ::Gitlab::Llm::VertexAi::ResponseModifiers::Predictions.new(
              { error: { message: DEFAULT_ERROR } }.to_json
            )

            ::Gitlab::Llm::GraphqlSubscriptionResponseService.new(
              user, merge_request, response_modifier, options: options
            ).execute
          end

          private

          def response_for(user, merge_request, path)
            template = ai_prompt_class.new(merge_request, path)
            client_class = ::Gitlab::Llm::VertexAi::Client
            client_class.new(user)
              .code(content: template.to_prompt, **template.options(client_class))
          end

          def vertex_ai?(merge_request)
            Feature.enabled?(:generate_test_file_vertex, merge_request.project)
          end
        end
      end
    end
  end
end
