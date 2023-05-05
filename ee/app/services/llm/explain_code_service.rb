# frozen_string_literal: true

module Llm
  class ExplainCodeService < BaseService
    TOTAL_MODEL_TOKEN_LIMIT = 4096
    MAX_RESPONSE_TOKENS = 300

    # Let's use a low multiplier until we're able to correctly calculate the number of tokens
    INPUT_CONTENT_LIMIT = (TOTAL_MODEL_TOKEN_LIMIT - MAX_RESPONSE_TOKENS) * 4

    def valid?
      super &&
        Feature.enabled?(:explain_code_snippet, user) &&
        resource.licensed_feature_available?(:explain_code) &&
        resource.root_ancestor.experiment_features_enabled
    end

    private

    def perform
      return error('The messages are too big') if messages_are_too_big?

      ::Llm::CompletionWorker.perform_async(user.id, resource.id, resource.class.name, :explain_code, options)

      success
    end

    def messages_are_too_big?
      options[:messages].sum { |message| message[:content].size } > INPUT_CONTENT_LIMIT
    end
  end
end
