# frozen_string_literal: true

module Llm
  module Embedding
    module GitlabDocumentation
      class SetEmbeddingsOnTheRecordWorker
        include ApplicationWorker
        include Gitlab::ExclusiveLeaseHelpers

        TRACKING_CONTEXT = { action: 'documentation_embedding' }.freeze
        MODEL = ::Embedding::Vertex::GitlabDocumentation

        idempotent!
        worker_has_external_dependencies!
        data_consistency :delayed
        feature_category :duo_chat
        urgency :throttled
        sidekiq_options retry: 5

        def perform(id, update_version)
          return unless Feature.enabled?(:openai_experimentation) # this is legacy global AI toggle FF
          return unless Feature.enabled?(:create_embeddings_with_vertex_ai) # embeddings supported by vertex FF
          return unless ::License.feature_available?(:ai_chat) # license check

          record = MODEL.find_by_id(id)
          return unless record

          client = ::Gitlab::Llm::VertexAi::Client.new(nil, tracking_context: TRACKING_CONTEXT)
          result = client.text_embeddings(content: record.content)

          unless result.success? && result.has_key?('predictions')
            raise StandardError, result.dig('error', 'message') || "Could not generate embedding: '#{result}'"
          end

          embedding = result['predictions'].first['embeddings']['values']
          record.update!(embedding: embedding)

          source = record.metadata["source"]
          current_version = MODEL.current_version

          in_lock("#{source}/update_version/#{update_version}", ttl: 10.minutes, sleep_sec: 1) do
            new_embeddings = MODEL.for_source(source).for_version(update_version)

            break unless new_embeddings.exists?
            break if MODEL.for_source(source).nil_embeddings_for_version(update_version).exists?

            old_embeddings = MODEL.for_version(update_version).invert_where.for_source(source)
            old_embeddings.each_batch(of: 100) { |batch| batch.delete_all } # rubocop:disable Style/SymbolProc

            new_embeddings.each_batch(of: 100) { |batch| batch.update_all(version: current_version) } # rubocop:disable Style/SymbolProc
          end
        end
      end
    end
  end
end
