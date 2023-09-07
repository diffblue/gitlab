# frozen_string_literal: true

module CodeSuggestions
  module Tasks
    class CodeCompletion < Base
      extend ::Gitlab::Utils::Override

      GATEWAY_PROMPT_VERSION = 1

      override :endpoint_name
      def endpoint_name
        'completions'
      end

      override :body
      def body
        params.merge(prompt_version: GATEWAY_PROMPT_VERSION).to_json
      end
    end
  end
end
