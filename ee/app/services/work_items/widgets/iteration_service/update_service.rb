# frozen_string_literal: true

module WorkItems
  module Widgets
    module IterationService
      class UpdateService < WorkItems::Widgets::BaseService
        def before_update_callback(params: {})
          return unless params.present? && params.key?(:iteration)
          return unless has_permission?(:admin_work_item)

          if params[:iteration].nil?
            work_item.iteration = nil

            return
          end

          return unless in_the_same_group_hierarchy?(params[:iteration])

          work_item.iteration = params[:iteration]
        end

        private

        def in_the_same_group_hierarchy?(iteration)
          return false unless work_item.project.group.present?

          group_ids = work_item.project.group.self_and_ancestors.select(:id)

          # rubocop: disable CodeReuse/ActiveRecord
          ::Iteration.of_groups(group_ids).exists?(id: iteration.id)
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
