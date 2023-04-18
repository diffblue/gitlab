# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      class ResponseService < BaseService
        def initialize(user, resource, ai_response, options:)
          @user = user
          @resource = resource
          @ai_response = Gitlab::Json.parse(ai_response, symbolize_names: true)
          @options = options
        end

        def execute(response_modifier = Gitlab::Llm::OpenAi::ResponseModifiers::Completions.new)
          return unless user

          data = {
            id: SecureRandom.uuid,
            model_name: resource.class.name,
            # todo: do we need to sanitize/refine this response in any ways?
            response_body: response_modifier.execute(ai_response).to_s.strip,
            errors: [ai_response&.dig(:error)].compact
          }

          GraphqlTriggers.ai_completion_response(user.to_global_id, resource.to_global_id, data)
        end

        private

        attr_reader :user, :resource, :ai_response, :options
      end
    end
  end
end
