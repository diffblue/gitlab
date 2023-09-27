# frozen_string_literal: true

module Llm
  module Embedding
    module GitlabDocumentation
      class CreateDbEmbeddingsPerDocFileWorker
        include ApplicationWorker
        include Gitlab::ExclusiveLeaseHelpers
        include EmbeddingsWorkerContext

        MODEL = ::Embedding::Vertex::GitlabDocumentation
        EMBEDDINGS_PER_SECOND = 7

        idempotent!
        data_consistency :always # rubocop: disable SidekiqLoadBalancing/WorkerDataConsistency
        feature_category :duo_chat
        urgency :throttled
        sidekiq_options retry: 5
        loggable_arguments 0

        def perform(filename, update_version)
          return unless Feature.enabled?(:openai_experimentation) # this is legacy global AI toggle FF
          return unless Feature.enabled?(:create_embeddings_with_vertex_ai) # embeddings supported by vertex FF
          return unless ::License.feature_available?(:ai_chat) # license check

          # if this job gets rescheduled too much it may so happen the file is not there anymore
          return unless File.exist?(filename)

          in_lock("#{self.class.name.underscore}/version/#{update_version}", ttl: 10.minutes, sleep_sec: 1) do
            @update_version = update_version
            @filename = filename
            delay = 0
            records = []
            content = File.read(filename)
            source = filename.gsub(Rails.root.to_s, '')
            embeddings_index = self.class.get_embeddings_index

            # This worker needs to be idempotent, so that in case of a failure, if this worker is re-run, we make
            # sure we do not create duplicate entries for the same file. For that reason, we cleanup any records
            # for the passed in filename and given update_version.
            file_embeddings = MODEL.select(:id).for_source(source).for_version(update_version)
            file_embeddings.each_batch(of: BATCH_SIZE) { |batch| batch.delete_all } # rubocop:disable Style/SymbolProc

            items = ::Gitlab::Llm::Embeddings::Utils::DocsContentParser.parse_and_split(content, source, DOC_DIRECTORY)

            items.each do |item|
              embeddings_index += 1
              records << build_record(item)

              # Vertex has 600 requests per minute(i.e. 10 req/sec) quota for embeddings endpoint based on
              # https://cloud.google.com/vertex-ai/docs/quotas#request_quotas,
              # so let's schedule roughly ~7 jobs per second
              delay = (embeddings_index / EMBEDDINGS_PER_SECOND) + 1

              if embeddings_index % EMBEDDINGS_PER_SECOND == 0
                bulk_create_records(records, delay)
                records = []
              end
            end

            # bulk insert whatever is left in records array
            bulk_create_records(records, delay) unless records.blank?
            # update embeddings index for the next worker run
            self.class.set_embeddings_index!(embeddings_index)
          end
        end

        private

        attr_reader :update_version, :filename

        def bulk_create_records(records, delay)
          embedding_ids = MODEL.bulk_insert!(records, returns: :ids)
          logger.info(
            structured_payload(
              message: 'Creating DB embedding records',
              filename: filename,
              new_embeddings: embedding_ids,
              new_version: update_version
            )
          )

          embedding_ids.each do |record_id|
            SetEmbeddingsOnTheRecordWorker.perform_in(delay.seconds, record_id, update_version)
          end
        end

        def build_record(item)
          current_time = Time.current

          ::Embedding::Vertex::GitlabDocumentation.new(
            created_at: current_time,
            updated_at: current_time,
            embedding: item[:embedding],
            metadata: item[:metadata],
            content: item[:content],
            url: item[:url],
            version: update_version
          )
        end
      end
    end
  end
end
