# frozen_string_literal: true

module Llm
  class ChatService < BaseService
    private

    def perform
      worker_perform(user, resource, :chat, options)
    end

    def valid?
      super &&
        resource.resource_parent.licensed_feature_available?(:ai_chat) &&
        Gitlab::Llm::StageCheck.available?(resource.resource_parent.root_ancestor, :chat) &&
        Feature.enabled?(:gitlab_duo, user)
    end

    # We need to broadcast this content over the websocket as well
    # https://gitlab.com/gitlab-org/gitlab/-/issues/413600
    def content(_action_name)
      options[:content]
    end
  end
end
