# frozen_string_literal: true

module Llm
  module Embedding
    module GitlabDocumentation
      class CreateEmptyEmbeddingsRecordsWorker
        include ApplicationWorker
        include CronjobQueue # rubocop:disable Scalability/CronWorkerContext
        include Gitlab::ExclusiveLeaseHelpers

        idempotent!
        data_consistency :always # rubocop: disable SidekiqLoadBalancing/WorkerDataConsistency
        feature_category :duo_chat
        urgency :throttled
        sidekiq_options retry: 3

        DOC_DIRECTORY = 'doc'

        def perform
          return unless Feature.enabled?(:openai_experimentation) # this is legacy global AI toggle FF
          return unless Feature.enabled?(:gitlab_duo) # chat specific FF
          return unless Feature.enabled?(:create_embeddings_with_vertex_ai) # embeddings supported by vertex FF
          return unless ::License.feature_available?(:ai_chat) # license check

          index = 0
          in_lock("#{self.class.name.underscore}/version/#{version}", ttl: 10.minutes, sleep_sec: 1) do
            files.each do |filename|
              content = File.read(filename)
              filename.gsub!(Rails.root.to_s, '')

              items = ::Gitlab::Llm::Embeddings::Utils::DocsContentParser.parse_and_split(
                content, filename, DOC_DIRECTORY
              )

              items.each do |item|
                index += 1
                record = create_record(item)

                # Vertex has 600 requests per minute(i.e. 10 req/sec) quota for embeddings endpoint based on
                # https://cloud.google.com/vertex-ai/docs/quotas#request_quotas,
                # so let's schedule roughly ~7 jobs per second
                delay = (index / 7) + 1

                ::Llm::Embedding::GitlabDocumentation::SetEmbeddingsOnTheRecordWorker.perform_in(
                  delay.seconds, record.id, version
                )
              end
            end
          end
        end

        private

        def files
          Dir[Rails.root.join("#{DOC_DIRECTORY}/**/*.md")]
        end

        def create_record(item)
          ::Embedding::Vertex::GitlabDocumentation.create!(
            metadata: item[:metadata],
            content: item[:content],
            url: item[:url],
            version: version
          )
        end

        def version
          @version ||= ::Embedding::Vertex::GitlabDocumentation.get_current_version + 1
        end
      end
    end
  end
end
