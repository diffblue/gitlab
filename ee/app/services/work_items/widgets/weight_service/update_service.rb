# frozen_string_literal: true

module WorkItems
  module Widgets
    module WeightService
      class UpdateService < WorkItems::Widgets::BaseService
        def before_update_callback(params: {})
          params[:weight] = nil if new_type_excludes_widget?

          return unless params.present? && params.key?(:weight)
          return unless weight_available? && has_permission?(:admin_work_item)

          work_item.weight = params[:weight]
        end

        private

        def weight_available?
          work_item.weight_available?
        end
      end
    end
  end
end
