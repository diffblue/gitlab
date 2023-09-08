# frozen_string_literal: true

module Geo
  # Updates all the registries for a given registry_class
  class RegistryBulkUpdateService
    include ::Gitlab::Geo::LogHelpers

    def initialize(action, registry_class)
      @action = action
      @registry_class = registry_class
    end

    def execute
      case action.to_sym
      when :reverify_all
        reverify_all
      when :resync_all
        resync_all
      else
        action_not_supported
      end
    rescue StandardError => e
      error_in_action(e)
    end

    private

    attr_reader :action, :registry_class

    def reverify_all
      Geo::BulkMarkVerificationPendingBatchWorker.perform_with_capacity(registry_class)

      success_response(_('Registries enqueued to be reverified'))
    end

    def resync_all
      Geo::BulkMarkPendingBatchWorker.perform_with_capacity(registry_class)

      success_response(_('Registries enqueued to be resynced'))
    end

    def action_not_supported
      ServiceResponse.error(
        message: format(_("Action '%{action}' in registries is not supported."), action: action)
      )
    end

    def error_in_action(error)
      log_error(
        "Could not update registries with action: #{action}",
        error.message,
        registry_class: registry_class
      )

      ServiceResponse.error(
        message: format(_("An error occurred while trying to update the registries: '%{error_message}'."),
          error_message: error.message)
      )
    end

    def success_response(message)
      ServiceResponse.success(message: message, payload: { registry_class: registry_class })
    end
  end
end
