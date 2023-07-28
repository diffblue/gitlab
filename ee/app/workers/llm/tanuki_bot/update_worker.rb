# frozen_string_literal: true

module Llm
  module TanukiBot
    class UpdateWorker
      include ApplicationWorker
      include Gitlab::ExclusiveLeaseHelpers

      idempotent!
      data_consistency :delayed
      feature_category :ai_abstraction_layer
      urgency :throttled

      sidekiq_options retry: 1

      def perform(id, version)
        return unless Feature.enabled?(:openai_experimentation)
        return unless Feature.enabled?(:tanuki_bot)
        return unless ::License.feature_available?(:ai_tanuki_bot)

        record = ::Embedding::TanukiBotMvc.find_by_id(id)
        return unless record

        client = ::Gitlab::Llm::OpenAi::Client.new(nil)

        result = client.embeddings(input: record.content, moderated: false)

        unless result.success? && result.has_key?('data')
          raise StandardError, result.dig('error', 'message') || "Could not generate embedding: '#{result}'"
        end

        embedding = result['data'].first['embedding']
        record.update!(embedding: embedding)

        return if ::Embedding::TanukiBotMvc.nil_embeddings_for_version(version).exists?

        in_lock("#{self.class.name.underscore}/version/#{version}", sleep_sec: 1) do
          ::Embedding::TanukiBotMvc.set_current_version!(version)

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
