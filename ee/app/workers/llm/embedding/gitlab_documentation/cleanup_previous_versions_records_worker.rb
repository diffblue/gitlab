# frozen_string_literal: true

module Llm
  module Embedding
    module GitlabDocumentation
      class CleanupPreviousVersionsRecordsWorker
        include ApplicationWorker
        include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

        idempotent!
        data_consistency :always # rubocop: disable SidekiqLoadBalancing/WorkerDataConsistency
        feature_category :duo_chat
        urgency :throttled

        BATCH_SIZE = 1000
        TIME_LIMIT = 3.minutes

        def perform
          return unless Feature.enabled?(:openai_experimentation) # this is legacy global AI toggle FF
          return unless Feature.enabled?(:create_embeddings_with_vertex_ai) # embeddings supported by vertex FF
          return unless ::License.feature_available?(:ai_chat) # license check

          ::Embedding::Vertex::GitlabDocumentation.previous.limit(BATCH_SIZE).delete_all

          return unless ::Embedding::Vertex::GitlabDocumentation.previous.exists?

          Llm::Embedding::GitlabDocumentation::CleanupPreviousVersionsRecordsWorker.perform_in(10.seconds)
        end
      end
    end
  end
end
