# frozen_string_literal: true

module Llm
  class ExplainCodeService < BaseService
    TOTAL_MODEL_TOKEN_LIMIT = 4096
    MAX_RESPONSE_TOKENS = 300

    # Let's use a low multiplier until we're able to correctly calculate the number of tokens
    INPUT_CONTENT_LIMIT = (TOTAL_MODEL_TOKEN_LIMIT - MAX_RESPONSE_TOKENS) * 4

    def valid?
      super &&
        Feature.enabled?(:openai_experimentation, user) &&
        resource.licensed_feature_available?(:explain_code) &&
        Gitlab::Llm::StageCheck.available?(resource, :explain_code)
    end

    private

    def perform
      return error('The messages are too big') if messages_are_too_big?

      worker_perform(user, resource, feature_type, options)
    end

    def messages_are_too_big?
      options[:messages].sum { |message| message[:content].size } > INPUT_CONTENT_LIMIT
    end

    def feature_type
      if Feature.enabled?(:explain_code_vertex_ai, user)
        :explain_code
      else
        :explain_code_open_ai
      end
    end

    # Use `Explain code` command for GitLab Duo for both VertexAI and OpenAI models
    # When/if one of the implementations removed, this method can be removed as well
    def content(_)
      super(:explain_code)
    end
  end
end
