# frozen_string_literal: true

module WorkItems
  module Widgets
    module IterationService
      class CreateService < WorkItems::Widgets::IterationService::BaseService
        def before_create_callback(params: {})
          handle_iteration_change(params: params)
        end
      end
    end
  end
end
