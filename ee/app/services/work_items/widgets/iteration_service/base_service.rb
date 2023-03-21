# frozen_string_literal: true

module WorkItems
  module Widgets
    module IterationService
      class BaseService < WorkItems::Widgets::BaseService
        private

        def handle_iteration_change(params:)
          return unless params.present? && params.key?(:iteration)
          return unless has_permission?(:admin_work_item)

          if params[:iteration].nil?
            work_item.iteration = nil

            return
          end

          return unless in_the_same_group_hierarchy?(params[:iteration])

          work_item.iteration = params[:iteration]
        end

        def in_the_same_group_hierarchy?(iteration)
          group_ids = (work_item.project&.group || work_item.namespace).self_and_ancestors.select(:id)

          # rubocop: disable CodeReuse/ActiveRecord
          ::Iteration.of_groups(group_ids).exists?(id: iteration.id)
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
