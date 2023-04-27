# frozen_string_literal: true

module Gitlab
  module Llm
    class TanukiBot
      include ::Gitlab::Loggable

      DEFAULT_OPTIONS = {
        max_tokens: 256,
        top_p: 1,
        n: 1,
        best_of: 1
      }.freeze
      REQUEST_TIMEOUT = 30
      CONTENT_ID_FIELD = 'ATTRS'
      CONTENT_ID_REGEX = /CNT-IDX-(?<id>\d+)/
      RECORD_LIMIT = 7

      def self.execute(current_user:, question:, logger: nil)
        new(current_user: current_user, question: question, logger: logger).execute
      end

      def self.enabled_for?(user:)
        return false unless user
        return false unless ::License.feature_available?(:ai_tanuki_bot)
        return false unless Feature.enabled?(:openai_experimentation) && Feature.enabled?(:tanuki_bot, user)
        return false if ::Gitlab.com? && !user&.has_paid_namespace?(plans: [::Plan::ULTIMATE])

        true
      end

      def initialize(current_user:, question:, logger: nil)
        @current_user = current_user
        @question = question
        @logger = logger || Gitlab::AppJsonLogger.build
      end

      def execute
        return {} unless question.present?
        return {} unless self.class.enabled_for?(user: current_user)

        search_documents = query_search_documents
        return empty_response if search_documents.empty?

        get_completions(search_documents)
      end

      private

      attr_reader :current_user, :question, :logger

      def client
        @client ||= ::Gitlab::Llm::OpenAi::Client.new(current_user, request_timeout: REQUEST_TIMEOUT)
      end

      def build_initial_prompts(search_documents)
        search_documents.to_h do |doc|
          prompt = Gitlab::Llm::OpenAi::Templates::TanukiBot.initial_prompt(question: question, content: doc[:content])

          [doc, prompt[:prompt]]
        end
      end

      def send_initial_prompt(doc:, prompt:)
        result = client.completions(prompt: prompt, **DEFAULT_OPTIONS)

        info(
          document_id: doc[:id],
          prompt: prompt,
          status_code: result.code,
          openai_completions_response: result.parsed_response,
          message: 'Initial prompt request'
        )

        raise result.dig('error', 'message') || "Initial prompt request failed with '#{result}'" unless result.success?

        doc.merge(extracted_text: result['choices'].first['text'])
      end

      def sequential_competion(search_documents)
        prompts = build_initial_prompts(search_documents)

        prompts.map do |doc, prompt|
          send_initial_prompt(doc: doc, prompt: prompt)
        end
      end

      def parallel_completion(search_documents)
        prompts = build_initial_prompts(search_documents)

        threads = prompts.map do |doc, prompt|
          Thread.new do
            send_initial_prompt(doc: doc, prompt: prompt)
          end
        end

        threads.map(&:value)
      end

      def get_completions(search_documents)
        documents = if Feature.enabled?(:tanuki_bot_parallel)
                      parallel_completion(search_documents)
                    else
                      sequential_competion(search_documents)
                    end

        final_prompt = Gitlab::Llm::OpenAi::Templates::TanukiBot.final_prompt(question: question, documents: documents)

        final_prompt_result = client.completions(prompt: final_prompt[:prompt], **final_prompt[:options])

        unless final_prompt_result.success?
          raise final_prompt_result.dig('error', 'message') || "Final prompt failed with '#{final_prompt_result}'"
        end

        info(
          prompt: final_prompt,
          status_code: final_prompt_result.code,
          openai_completions_response: final_prompt_result.parsed_response,
          message: 'Final prompt request'
        )

        final_prompt_result
      end

      def query_search_documents
        embeddings_result = client.embeddings(input: question)
        question_embedding = embeddings_result['data'].first['embedding']

        nearest_neighbors = ::Embedding::TanukiBotMvc.neighbor_for(question_embedding).limit(RECORD_LIMIT)
        nearest_neighbors.map do |item|
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
          msg: _("I do not know."),
          sources: []
        }
      end

      def info(payload)
        return unless logger

        logger.info(build_structured_payload(**payload))
      end
    end
  end
end
