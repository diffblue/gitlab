# frozen_string_literal: true

module Gitlab
  module Metrics
    module Llm
      class << self
        def initialize_slis!
          tool_labels = Gitlab::Llm::Completions::Chat::TOOLS.map { |tool_class| { tool: tool_class::Executor::NAME } }
          tool_labels << { tool: :unknown }

          Gitlab::Metrics::Sli::Apdex.initialize_sli(:llm_chat_answers, tool_labels)
          Gitlab::Metrics::Sli::Apdex.initialize_sli(:llm_client_request, [
            { client: :anthropic },
            { client: :vertex_ai },
            { client: :open_ai }
          ])
        end
      end
    end
  end
end
