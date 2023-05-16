# frozen_string_literal: true

module Geo
  # Accepts a registry id if the update affects one unique registry entry.
  class RegistryUpdateService
    include ::Gitlab::Geo::LogHelpers

    attr_reader :registry_class, :registry

    delegate :replicator, to: :registry
    delegate :model_record, to: :replicator

    def initialize(action, registry_class, registry)
      @action = action
      @registry_class = registry_class.safe_constantize
      @registry = registry
    end

    def execute
      update_registry
    end

    private

    attr_reader :action

    def update_registry
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

    def reverify
      replicator.verify_async

      ServiceResponse.success(message: _('Registry entry enqueued to be reverified'), payload: { registry: registry })
    end

    def resync
      replicator.enqueue_sync

      ServiceResponse.success(message: _('Registry entry enqueued to be resynced'), payload: { registry: registry })
    end

    def action_not_supported
      ServiceResponse.error(
        message: format(_("Action '%{action}' in registry %{registry_id} entry is not supported."),
          action: action, registry_id: registry&.id)
      )
    end

    def error_in_action(error)
      log_error("Could not update registry entry with action: #{action}", error.message, registry_id: registry&.id)
      ServiceResponse.error(message: format(_(error.message)))
    end
  end
end
