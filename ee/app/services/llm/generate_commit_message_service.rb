# frozen_string_literal: true

module Llm
  class GenerateCommitMessageService < BaseService
    def valid?
      super &&
        Feature.enabled?(:generate_commit_message_flag, user) &&
        resource.resource_parent.root_ancestor.licensed_feature_available?(:generate_commit_message) &&
        Gitlab::Llm::StageCheck.available?(resource.resource_parent, :generate_commit_message)
    end

    private

    def perform
      worker_perform(user, resource, :generate_commit_message, options)
    end
  end
end
