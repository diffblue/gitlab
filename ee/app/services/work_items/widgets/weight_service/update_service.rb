# frozen_string_literal: true

module WorkItems
  module Widgets
    module WeightService
      class UpdateService < WorkItems::Widgets::BaseService
        def update(params: {})
          return unless params.present? && params[:weight]

          weight = params.delete(:weight)

          return unless weight_available? && can_admin_work_item?

          widget.work_item.weight = weight
        end

        private

        def weight_available?
          widget.work_item.weight_available?
        end
      end
    end
  end
end
