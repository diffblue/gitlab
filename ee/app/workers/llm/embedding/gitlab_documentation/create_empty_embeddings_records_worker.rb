# frozen_string_literal: true

module Llm
  module Embedding
    module GitlabDocumentation
      class CreateEmptyEmbeddingsRecordsWorker
        include ApplicationWorker
        include CronjobQueue # rubocop:disable Scalability/CronWorkerContext
        include Gitlab::ExclusiveLeaseHelpers
        include EmbeddingsWorkerContext

        MODEL = ::Embedding::Vertex::GitlabDocumentation

        idempotent!
        data_consistency :always # rubocop: disable SidekiqLoadBalancing/WorkerDataConsistency
        feature_category :duo_chat
        urgency :throttled
        sidekiq_options retry: 3

        def perform
          return unless Feature.enabled?(:openai_experimentation) # this is legacy global AI toggle FF
          return unless Feature.enabled?(:create_embeddings_with_vertex_ai) # file_embeddings supported by vertex FF
          return unless ::License.feature_available?(:ai_chat) # license check

          # reset the indexing on chunks to be embedded, this is going to be used to ensure VertexAI embeddings API
          # quotas/limits are respected.
          in_lock("#{self.class.name.underscore}/version/#{update_version}", ttl: 10.minutes, sleep_sec: 1) do
            self.class.set_embeddings_index!(0)

            embeddings_sources = extract_embedding_sources

            files.each do |filename|
              content = File.read(filename)
              source = filename.gsub(Rails.root.to_s, '')

              next unless embeddable?(content)

              current_md5sum = extract_md5sum(embeddings_sources, source)
              new_md5sum = OpenSSL::Digest::SHA256.hexdigest(content)

              # if file content did not change, then no need to rebuild it's file_embeddings, just used them as is.
              next if new_md5sum == current_md5sum

              CreateDbEmbeddingsPerDocFileWorker.perform_async(filename, update_version)
              logger.info(
                structured_payload(
                  message: 'Enqueued DB embeddings creation',
                  filename: filename,
                  new_version: update_version
                )
              )
            end

            cleanup_embeddings_for_missing_files(embeddings_sources)
          end
        end

        private

        def extract_embedding_sources
          embeddings_sources = Set.new
          select_columns = "distinct version, metadata->>'source' as source, metadata->>'md5sum' as md5sum"

          MODEL.select(select_columns).each_batch do |batch|
            data = batch.map do |em|
              { version: em.version, source: em.source, md5sum: em.md5sum }.with_indifferent_access
            end

            embeddings_sources.merge(data)
          end

          embeddings_sources.group_by { |em| em[:source] }
        end

        def extract_md5sum(embeddings_sources, source)
          embeddings_for_source = embeddings_sources.delete(source)
          embedding = embeddings_for_source&.find { |embedding| embedding[:version] == MODEL.current_version }

          embedding&.dig('md5sum')
        end

        def embeddable?(content)
          return false if content.empty?
          return false if content.include?('This document was moved to [another location]')

          true
        end

        def cleanup_embeddings_for_missing_files(embeddings_sources)
          embeddings_sources.keys.each_slice(20) do |sources|
            MODEL.for_sources(sources).each_batch(of: BATCH_SIZE) { |batch| batch.delete_all } # rubocop:disable Style/SymbolProc

            logger.info(
              structured_payload(
                message: 'Deleting embeddings for missing files',
                filename: sources,
                new_version: MODEL.current_version
              )
            )
          end
        end

        def files
          Dir[Rails.root.join("#{DOC_DIRECTORY}/**/*.md")]
        end

        def update_version
          @update_version ||= MODEL.current_version + 1
        end
      end
    end
  end
end
