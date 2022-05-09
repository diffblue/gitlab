# frozen_string_literal: true

module Namespaces
  class UpdatePreventSharingOutsideHierarchyService
    STATE = true

    def initialize(namespace)
      @namespace = namespace
    end

    def execute
      return unless namespace && needs_updating?

      update_setting
      log_event

    rescue StandardError => ex
      log_error(ex)
    end

    private

    attr_reader :namespace

    def needs_updating?
      namespace.prevent_sharing_groups_outside_hierarchy != STATE
    end

    def update_setting
      namespace.update_attribute(:prevent_sharing_groups_outside_hierarchy, STATE)
    end

    def log_event
      log_params = {
        namespace: namespace.id,
        message: "Setting the namespace setting for prevent_sharing_groups_outside_hierarchy to #{STATE}"
      }

      Gitlab::AppLogger.info(log_params)
    end

    def log_error(ex)
      log_params = {
        namespace: namespace.id,
        message: 'An error has occurred',
        details: ex.message
      }

      Gitlab::AppLogger.error(log_params)
    end
  end
end
