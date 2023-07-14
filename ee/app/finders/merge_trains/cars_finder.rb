# frozen_string_literal: true

module MergeTrains
  class CarsFinder
    # Without params finds all the cars regardless of train for a project
    # Finds a full train of cars when @params[:target_branch] is passed.
    # Consider making target_branch required: https://gitlab.com/gitlab-org/gitlab/-/issues/406356
    # Use @params[:scope] to filter the cars by 'active' or 'complete' car statuses
    def initialize(project, current_user, params = {})
      @project = project
      @current_user = current_user
      @merge_train_cars = project.merge_train_cars
      @params = params
    end

    def execute
      return MergeTrains::Car.none unless Ability.allowed?(@current_user, :read_merge_train, @project)

      items = @merge_train_cars
      items = for_target(items, @params[:target_branch])
      items = by_scope(items)

      sort(items)
    end

    private

    def by_scope(items)
      case @params[:scope]
      when 'active'
        items.active
      when 'complete'
        items.complete
      else
        items
      end
    end

    def sort(items)
      return items unless %w[asc desc].include?(@params[:sort])

      items.by_id(@params[:sort].to_sym)
    end

    def for_target(items, target_branch)
      return items unless target_branch

      items.for_target(@project, target_branch)
    end
  end
end
