# frozen_string_literal: true

module Geo
  # Updates a Geo registry entry through reverify or resync actions
  class RegistryUpdateService
    include ::Gitlab::Geo::LogHelpers

    attr_reader :registry

    delegate :replicator, to: :registry
    delegate :model_record, to: :replicator

    def initialize(action, registry)
      @action = action
      @registry = registry
    end

    def execute
      case action.to_sym
      when :reverify
        reverify
      when :resync
        resync
      else
        action_not_supported
      end
    rescue StandardError => e
      error_in_action(e)
    end

    private

    attr_reader :action

    def reverify
      replicator.verify_async

      success_response(_('Registry entry enqueued to be reverified'))
    end

    def resync
      replicator.enqueue_sync

      success_response(_('Registry entry enqueued to be resynced'))
    end

    def action_not_supported
      ServiceResponse.error(
        message: format(_("Action '%{action}' in registry %{registry_id} entry is not supported."),
          action: action, registry_id: registry.id)
      )
    end

    def error_in_action(error)
      log_error(
        "Could not update registry entry with action: #{action}",
        error.message,
        registry_id: registry.id
      )

      ServiceResponse.error(
        message: format(_("An error occurred while trying to update the registry: '%{error_message}'."),
          error_message: error.message)
      )
    end

    def success_response(message)
      ServiceResponse.success(message: message, payload: { registry: registry })
    end
  end
end
