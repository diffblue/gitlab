# frozen_string_literal: true

module Gitlab
  module Llm
    class TanukiBot
      include ::Gitlab::Loggable

      REQUEST_TIMEOUT = 30
      CONTENT_ID_FIELD = 'ATTRS'
      CONTENT_ID_REGEX = /CNT-IDX-(?<id>\d+)/
      RECORD_LIMIT = 4
      MODEL = 'claude-instant-1.1'

      def self.execute(current_user:, question:, logger: nil)
        new(current_user: current_user, question: question, logger: logger).execute
      end

      def self.enabled_for?(user:)
        return false unless user
        return false unless ::License.feature_available?(:ai_tanuki_bot)
        return false unless Feature.enabled?(:openai_experimentation) && Feature.enabled?(:tanuki_bot, user)
        return false unless ai_feature_enabled?(user)

        true
      end

      def self.ai_feature_enabled?(user)
        return true unless ::Gitlab.com?

        user.any_group_with_ai_available?
      end

      def self.show_breadcrumbs_entry_point_for?(user:)
        return false unless Feature.enabled?(:tanuki_bot_breadcrumbs_entry_point, user)

        enabled_for?(user: user)
      end

      def initialize(current_user:, question:, logger: nil)
        @current_user = current_user
        @question = question
        @logger = logger || Gitlab::Llm::Logger.build
        @correlation_id = Labkit::Correlation::CorrelationId.current_id
      end

      def execute
        return {} unless question.present?
        return {} unless self.class.enabled_for?(user: current_user)

        search_documents = query_search_documents
        return empty_response if search_documents.empty?

        get_completions(search_documents)
      end

      private

      attr_reader :current_user, :question, :logger, :correlation_id

      def openai_client
        @openai_client ||= ::Gitlab::Llm::OpenAi::Client.new(current_user, request_timeout: REQUEST_TIMEOUT)
      end

      def client
        @client ||= ::Gitlab::Llm::Anthropic::Client.new(current_user)
      end

      def get_completions(search_documents)
        final_prompt = Gitlab::Llm::Anthropic::Templates::TanukiBot
          .final_prompt(question: question, documents: search_documents)

        final_prompt_result = client.complete(
          prompt: final_prompt[:prompt],
          options: {
            model: "claude-instant-1.1"
          }
        )

        unless final_prompt_result.success?
          raise final_prompt_result.dig('error', 'message') || "Final prompt failed with '#{final_prompt_result}'"
        end

        logger.debug(message: "Got Final Result", content: {
          prompt: final_prompt[:prompt],
          status_code: final_prompt_result.code,
          openai_completions_response: final_prompt_result.parsed_response,
          message: 'Final prompt request'
        })

        final_prompt_result
      end

      def query_search_documents
        embeddings_result = openai_client.embeddings(input: question, moderated: false)
        question_embedding = embeddings_result['data'].first['embedding']

        ::Embedding::TanukiBotMvc.current.neighbor_for(
          question_embedding,
          limit: RECORD_LIMIT
        ).map do |item|
          item.metadata['source_url'] = item.url

          {
            id: item.id,
            content: item.content,
            metadata: item.metadata
          }
        end
      end

      def empty_response
        {
          content: _("I do not know."),
          sources: []
        }
      end

      def info(payload)
        return unless logger

        logger.info(build_structured_payload(**payload.merge(correlation_id: correlation_id)))
      end
    end
  end
end
