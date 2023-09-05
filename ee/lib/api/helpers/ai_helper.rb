# frozen_string_literal: true

module API
  module Helpers
    module AiHelper
      def check_feature_enabled!
        return if Feature.enabled?(:ai_experimentation_api, current_user)

        not_found!(::Llm::BaseService::INVALID_MESSAGE)
      end
    end
  end
end
