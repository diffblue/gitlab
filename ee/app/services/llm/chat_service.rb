# frozen_string_literal: true

module Llm
  class ChatService < BaseService
    private

    def perform
      worker_perform(user, resource, :chat, options.merge(skip_cache: false))
    end

    def valid?
      super && Feature.enabled?(:gitlab_duo, user)
    end

    # We need to broadcast this content over the websocket as well
    # https://gitlab.com/gitlab-org/gitlab/-/issues/413600
    def content(_action_name)
      options[:content]
    end
  end
end
