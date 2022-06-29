# frozen_string_literal: true

# Search for iterations
#
# params - Hash
#   parent - The group in which to look-up iterations.
#   include_ancestors - whether to look-up iterations in group ancestors.
#   title - Filter by title.
#   search - Filter by fuzzy searching the given query in the selected fields.
#   in - Array of searchable fields used with search param.
#   state - Filters by state.
#   sort - Items are sorted by due_date and title with id as a tie breaker if unspecified.

class IterationsFinder
  include FinderMethods
  include TimeFrameFilter
  include UpdatedAtFilter

  SEARCHABLE_FIELDS = %i(title cadence_title).freeze

  attr_reader :params, :current_user

  def initialize(current_user, params = {})
    @params = params
    @current_user = current_user
  end

  def execute(skip_authorization: false)
    @skip_authorization = skip_authorization

    handle_wildcard_params

    items = Iteration.all
    items = by_id(items)
    items = by_iid(items)
    items = by_groups(items)
    items = by_title(items)
    items = by_search(items)
    items = by_state(items)
    items = by_timeframe(items)
    items = by_iteration_cadences(items)
    items = by_updated_at(items)

    order(items)
  end

  private

  attr_reader :skip_authorization

  # wildcard params do not override other explicitly given params
  def handle_wildcard_params
    if params[:iteration_wildcard_id] && params[:iteration_wildcard_id].casecmp?(::Iteration::Predefined::Current.title)
      params[:start_date] ||= Date.today
      params[:end_date] ||= Date.today
    end
  end

  def by_groups(items)
    return Iteration.none unless skip_authorization || Ability.allowed?(current_user, :read_iteration, params[:parent])

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

  def by_search(items)
    return items unless params[:search].present? && params[:in].present?

    query = params[:search]
    in_title = params[:in].include?(:title)
    in_cadence_title = params[:in].include?(:cadence_title)

    if in_title && in_cadence_title
      items.search_title_or_cadence_title(query)
    elsif in_title
      items.search_title(query)
    elsif in_cadence_title
      items.search_cadence_title(query)
    end
  end

  def by_state(items)
    return items unless params[:state].present?

    Iteration.filter_by_state(items, params[:state])
  end

  def by_iteration_cadences(items)
    return items unless params[:iteration_cadence_ids].present?

    items.by_iteration_cadence_ids(params[:iteration_cadence_ids])
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def order(items)
    case params[:sort]
    when :cadence_and_due_date_asc
      items.sort_by_cadence_id_and_due_date_asc
    when :cadence_and_due_date_desc
      items.sort_by_cadence_id_and_due_date_desc
    else
      items.reorder(:due_date).order(:title, { id: :asc })
    end
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
