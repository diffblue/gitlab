# frozen_string_literal: true

module EE
  module TanukiBotHelper
    def show_tanuki_bot_chat?
      return false unless License.feature_available?(:ai_tanuki_bot)
      return false if ::Gitlab.com? && !current_user&.has_paid_namespace?(plans: [::Plan::ULTIMATE])

      ::Feature.enabled?(:openai_experimentation) && ::Feature.enabled?(:tanuki_bot, current_user)
    end
  end
end
