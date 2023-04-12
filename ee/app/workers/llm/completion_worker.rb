# frozen_string_literal: true

module Llm
  class CompletionWorker
    include ApplicationWorker

    idempotent!
    data_consistency :delayed
    feature_category :team_planning
    urgency :low

    def perform(user_id, resource_id, resource_class, ai_action_name)
      return unless Feature.enabled?(:openai_experimentation)

      user = User.find_by_id(user_id)
      return unless user

      resource = find_resource(resource_id, resource_class)
      return unless resource

      ai_completion = ::Gitlab::Llm::OpenAi::Completions::Factory.completion(ai_action_name.to_sym)
      ai_completion.execute(user, resource) if ai_completion
    end

    private

    def find_resource(resource_id, resource_class)
      resource_class.classify.constantize.find_by_id(resource_id)
    end
  end
end
