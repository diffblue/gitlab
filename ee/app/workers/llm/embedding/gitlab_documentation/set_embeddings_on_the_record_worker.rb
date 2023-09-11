# frozen_string_literal: true

module Llm
  module Embedding
    module GitlabDocumentation
      class SetEmbeddingsOnTheRecordWorker
        include ApplicationWorker
        include Gitlab::ExclusiveLeaseHelpers

        TRACKING_CONTEXT = { action: 'documentation_embedding' }.freeze

        idempotent!
        data_consistency :delayed
        feature_category :duo_chat
        urgency :throttled

        sidekiq_options retry: 1

        def perform(id, version)
          return unless Feature.enabled?(:openai_experimentation) # this is legacy global AI toggle FF
          return unless Feature.enabled?(:gitlab_duo) # chat specific FF
          return unless Feature.enabled?(:create_embeddings_with_vertex_ai) # embeddings supported by vertex FF
          return unless ::License.feature_available?(:ai_chat) # license check

          record = ::Embedding::Vertex::GitlabDocumentation.find_by_id(id)
          return unless record

          client = ::Gitlab::Llm::VertexAi::Client.new(nil, tracking_context: TRACKING_CONTEXT)

          result = client.text_embeddings(content: record.content)

          unless result.success? && result.has_key?('predictions')
            raise StandardError, result.dig('error', 'message') || "Could not generate embedding: '#{result}'"
          end

          embedding = result['predictions'].first['embeddings']['values']
          record.update!(embedding: embedding)

          return if ::Embedding::Vertex::GitlabDocumentation.nil_embeddings_for_version(version).exists?

          in_lock("#{self.class.name.underscore}/version/#{version}", sleep_sec: 1) do
            ::Embedding::Vertex::GitlabDocumentation.set_current_version!(version)

            logger.info(
              structured_payload(
                message: 'Updated current version',
                version: version
              )
            )
          end
        end
      end
    end
  end
end
