# frozen_string_literal: true

module Ci
  module Llm
    class GenerateConfigWorker
      include ApplicationWorker
      include ::Gitlab::ExclusiveLeaseHelpers

      idempotent!
      deduplicate :until_executed, including_scheduled: true
      data_consistency :delayed
      feature_category :pipeline_composition
      urgency :high
      sidekiq_options retry: 3

      sidekiq_retries_exhausted do |job, _exception|
        ai_message = Ci::Editor::AiConversation::Message.find_by_id(job['args'][0])
        ai_message.update!(async_errors: ['Error fetching data'])
      end

      def perform(ai_message_id)
        Ci::Editor::AiConversation::Message.find_by_id(ai_message_id).try do |ai_message|
          ::Ci::Llm::GenerateConfigService.new(ai_message: ai_message).execute
        end
      end
    end
  end
end
