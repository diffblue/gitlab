# frozen_string_literal: true

module CodeSuggestions
  module Tasks
    class CodeCompletion < Base
      extend ::Gitlab::Utils::Override
      include Gitlab::Utils::StrongMemoize

      override :endpoint_name
      def endpoint_name
        'completions'
      end

      override :body
      def body
        unsafe_passthrough_params.merge(prompt.request_params).to_json
      end

      private

      def prompt
        if params[:model_family] == :anthropic
          CodeSuggestions::Prompts::CodeCompletion::Anthropic.new(params)
        else
          CodeSuggestions::Prompts::CodeCompletion::VertexAi.new(params)
        end
      end
      strong_memoize_attr :prompt
    end
  end
end
