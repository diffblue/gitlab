# frozen_string_literal: true

module Gitlab
  module Metrics
    module Llm
      class << self
        CLIENT_NAMES = {
          'Gitlab::Llm::VertexAi::Client' => :vertex_ai,
          'Gitlab::Llm::Anthropic::Client' => :anthropic,
          'Gitlab::Llm::OpenAi::Client' => :open_ai
        }.freeze

        def initialize_slis!
          completion_labels = Gitlab::Llm::CompletionsFactory::COMPLETIONS.values.map do |completion|
            { feature_category: completion[:feature_category], service_class: completion[:service_class].name }
          end

          Gitlab::Metrics::Sli::ErrorRate.initialize_sli(:llm_completion, completion_labels)
          Gitlab::Metrics::Sli::Apdex.initialize_sli(:llm_completion, completion_labels)

          client_labels = (CLIENT_NAMES.values + [:unknown]).map { |client| { client: client } }
          Gitlab::Metrics::Sli::ErrorRate.initialize_sli(:llm_client_request, client_labels)
        end

        def client_label(cls)
          CLIENT_NAMES.fetch(cls.name, :unknown)
        end
      end
    end
  end
end
