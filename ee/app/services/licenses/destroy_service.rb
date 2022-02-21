# frozen_string_literal: true

module Licenses
  class DestroyService < ::Licenses::BaseService
    extend ::Gitlab::Utils::Override

    override :execute
    def execute
      raise ActiveRecord::RecordNotFound unless license
      raise Gitlab::Access::AccessDeniedError unless can?(user, :destroy_licenses)

      clear_future_subscriptions
      license.destroy
    end

    private

    def clear_future_subscriptions
      return unless license.current?

      Gitlab::CurrentSettings.current_application_settings.update(future_subscriptions: [])
    end
  end
end
