# frozen_string_literal: true

module WorkItems
  module Widgets
    module IterationService
      class UpdateService < WorkItems::Widgets::IterationService::BaseService
        def before_update_callback(params: {})
          params[:iteration] = nil if new_type_excludes_widget?

          handle_iteration_change(params: params)
        end
      end
    end
  end
end
