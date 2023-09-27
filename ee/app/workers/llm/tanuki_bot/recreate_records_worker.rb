# frozen_string_literal: true

# DEPRECATED: This is to be removed once we move over to Vertex embeddings
# see https://gitlab.com/gitlab-org/gitlab/-/issues/420939
module Llm
  module TanukiBot
    class RecreateRecordsWorker
      include ApplicationWorker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext
      include Gitlab::ExclusiveLeaseHelpers

      idempotent!
      data_consistency :always # rubocop: disable SidekiqLoadBalancing/WorkerDataConsistency
      feature_category :duo_chat
      urgency :throttled
      sidekiq_options retry: 3

      DOC_DIRECTORY = 'doc'
      FILES_PER_MINUTE = 20

      def perform
        return unless Feature.enabled?(:openai_experimentation)
        return unless ::License.feature_available?(:ai_tanuki_bot)

        in_lock("#{self.class.name.underscore}/version/#{version}", ttl: 10.minutes, sleep_sec: 1) do
          files.each do |filename|
            content = File.read(filename)
            filename.gsub!(Rails.root.to_s, '')

            items = ::Gitlab::Llm::Embeddings::Utils::DocsContentParser.parse_and_split(
              content, filename, DOC_DIRECTORY
            )
            items.each do |item|
              record = create_record(item)
              Llm::TanukiBot::UpdateWorker.perform_in(rand(delay_in_seconds).seconds, record.id, version)
            end
          end
        end
      end

      private

      def files
        Dir[Rails.root.join("#{DOC_DIRECTORY}/**/*.md")]
      end

      def create_record(item)
        ::Embedding::TanukiBotMvc.create!(
          metadata: item[:metadata],
          content: item[:content],
          url: item[:url],
          version: version
        )
      end

      def version
        @version ||= ::Embedding::TanukiBotMvc.get_current_version + 1
      end

      def delay_in_seconds
        @delay_in_seconds ||= files.count.to_f / FILES_PER_MINUTE * 60 # minimum 3 seconds
      end
    end
  end
end
