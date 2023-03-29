# frozen_string_literal: true

module WorkItems
  module Widgets
    module HealthStatusService
      class UpdateService < WorkItems::Widgets::BaseService
        def before_update_callback(params:)
          params[:health_status] = nil if new_type_excludes_widget?

          return unless params&.key?(:health_status)
          return unless health_status_available? && has_permission?(:admin_work_item)

          work_item.health_status = params[:health_status]
        end

        def health_status_available?
          work_item.resource_parent&.feature_available?(:issuable_health_status)
        end
      end
    end
  end
end
