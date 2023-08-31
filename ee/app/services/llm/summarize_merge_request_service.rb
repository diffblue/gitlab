# frozen_string_literal: true

module Llm
  class SummarizeMergeRequestService < ::Llm::BaseService
    private

    def perform
      worker_perform(user, resource, :summarize_merge_request, options)
    end

    def valid?
      super &&
        resource.to_ability_name == "merge_request" &&
        Ability.allowed?(user, :summarize_merge_request, resource)
    end
  end
end
