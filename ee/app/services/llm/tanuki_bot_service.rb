# frozen_string_literal: true

module Llm
  class TanukiBotService < BaseService
    def valid?
      super && Gitlab::Llm::TanukiBot.enabled_for?(user: user)
    end

    private

    def perform
      worker_perform(user, resource, :tanuki_bot, options)
    end
  end
end
