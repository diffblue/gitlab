# frozen_string_literal: true

class MergeTrainsFinder
  attr_reader :project, :merge_trains, :params, :current_user

  def initialize(project, current_user, params = {})
    @project = project
    @current_user = current_user
    @merge_trains = project.merge_trains
    @params = params
  end

  def execute
    unless Ability.allowed?(current_user, :read_merge_train, project)
      return MergeTrains::Car.none
    end

    items = merge_trains
    items = for_target(items, params[:target_branch])
    items = by_scope(items)

    sort(items)
  end

  private

  def by_scope(items)
    case params[:scope]
    when 'active'
      items.active
    when 'complete'
      items.complete
    else
      items
    end
  end

  def sort(items)
    return items unless %w[asc desc].include?(params[:sort])

    items.by_id(params[:sort].to_sym)
  end

  def for_target(items, target_branch)
    return items unless target_branch

    items.for_target(project, target_branch)
  end
end
