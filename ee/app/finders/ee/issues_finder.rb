# frozen_string_literal: true

module EE
  module IssuesFinder
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Utils::StrongMemoize

    class_methods do
      extend ::Gitlab::Utils::Override

      override :scalar_params
      def scalar_params
        @scalar_params ||= super + [:weight, :epic_id, :include_subepics, :iteration_id, :iteration_title]
      end

      override :negatable_params
      def negatable_params
        @negatable_params ||= super + [:iteration_title, :weight]
      end
    end

    override :filter_items
    def filter_items(items)
      issues = by_weight(super)
      issues = by_epic(issues)
      by_iteration(issues)
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def by_weight(items)
      return items unless params.weights?

      if params.filter_by_no_weight?
        items.where(weight: [-1, nil])
      elsif params.filter_by_any_weight?
        items.where.not(weight: [-1, nil])
      else
        items.where(weight: params[:weight])
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def by_epic(items)
      return items unless params.by_epic?

      if params.filter_by_no_epic?
        items.no_epic
      elsif params.filter_by_any_epic?
        items.any_epic
      else
        items.in_epics(params.epics)
      end
    end

    def by_iteration(items)
      return items unless params.by_iteration?

      if params.filter_by_no_iteration?
        items.no_iteration
      elsif params.filter_by_any_iteration?
        items.any_iteration
      elsif params.filter_by_current_iteration? && get_current_iteration
        items.in_iterations(get_current_iteration)
      elsif params.filter_by_iteration_title?
        items.with_iteration_title(params[:iteration_title])
      else
        items.in_iterations(params[:iteration_id])
      end
    end

    override :filter_negated_items
    def filter_negated_items(items)
      items = by_negated_epic(items)
      items = by_negated_iteration(items)
      items = by_negated_weight(items)

      super(items)
    end

    def by_negated_weight(items)
      return items unless not_params[:weight].present?

      items.without_weights(not_params[:weight])
    end

    def by_negated_epic(items)
      return items unless not_params[:epic_id].present?

      items.not_in_epics(not_params[:epic_id].to_i)
    end

    def by_negated_iteration(items)
      return items unless not_params.by_iteration?

      if not_params.filter_by_current_iteration?
        items.not_in_iterations(get_current_iteration)
      elsif not_params.filter_by_iteration_title?
        items.without_iteration_title(not_params[:iteration_title])
      else
        items.not_in_iterations(not_params[:iteration_id])
      end
    end

    def get_current_iteration
      strong_memoize(:current_iteration) do
        next unless params.parent

        IterationsFinder.new(current_user, iterations_finder_params).execute.first
      end
    end

    def iterations_finder_params
      {
        parent: params.parent,
        include_ancestors: true,
        state: 'opened',
        start_date: Date.today,
        end_date: Date.today
      }
    end
  end
end
