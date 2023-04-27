# frozen_string_literal: true

module Llm
  class TanukiBotService < BaseService
    def valid?
      super && Gitlab::Llm::TanukiBot.enabled_for?(user: user)
    end

    private

    def perform
      ::Llm::CompletionWorker.perform_async(user.id, resource.id, resource.class.name, :tanuki_bot, options)

      success
    end
  end
end
