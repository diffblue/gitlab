# frozen_string_literal: true

# Search for iterations
#
# params - Hash
#   parent - The group in which to look-up iterations.
#   include_ancestors - whether to look-up iterations in group ancestors.
#   order - Orders by field default due date asc.
#   title - Filter by title.
#   state - Filters by state.

class IterationsFinder
  include FinderMethods
  include TimeFrameFilter

  attr_reader :params, :current_user

  def initialize(current_user, params = {})
    @params = params
    @current_user = current_user
  end

  def execute
    items = Iteration.all
    items = by_id(items)
    items = by_iid(items)
    items = by_groups(items)
    items = by_title(items)
    items = by_search_title(items)
    items = by_state(items)
    items = by_timeframe(items)
    items = by_iteration_cadences(items)

    order(items)
  end

  private

  def by_groups(items)
    return Iteration.none unless Ability.allowed?(current_user, :read_iteration, params[:parent])

    items.of_groups(groups)
  end

  def by_id(items)
    return items unless params[:id].present?

    items.id_in(params[:id])
  end

  def by_iid(items)
    params[:iid].present? ? items.iid_in(params[:iid]) : items
  end

  def by_title(items)
    return items unless params[:title].present?

    items.with_title(params[:title])
  end

  def by_search_title(items)
    return items unless params[:search_title].present?

    items.search_title(params[:search_title])
  end

  def by_state(items)
    return items unless params[:state].present?

    # `started` was deprecated in 14.1 in favor of `current`. Support for `started`
    # will be removed in 14.6 https://gitlab.com/gitlab-org/gitlab/-/issues/334018
    params[:state] = 'current' if params[:state] == 'started'

    Iteration.filter_by_state(items, params[:state])
  end

  def by_iteration_cadences(items)
    return items unless params[:iteration_cadence_ids].present?

    items.by_iteration_cadence_ids(params[:iteration_cadence_ids])
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def order(items)
    items.reorder(:due_date).order(:title, { id: :asc })
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def groups
    parent = params[:parent]

    group = case parent
            when Group
              parent
            when Project
              parent.parent
            else
              raise ArgumentError, 'Invalid parent class. Only Project and Group are supported.'
            end

    params[:include_ancestors] ? group.self_and_ancestors : group
  end
end
