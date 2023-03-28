# frozen_string_literal: true

module Epics
  class CreateService < Epics::BaseService
    prepend RateLimitedService

    rate_limit key: :issues_create, opts: { scope: [:current_user] }

    def execute
      set_date_params

      epic = group.epics.new

      create(epic)
    end

    private

    def before_create(epic)
      epic.move_to_start if epic.parent

      # current_user (defined in BaseService) is not available within run_after_commit block
      user = current_user
      epic.run_after_commit do
        NewEpicWorker.perform_async(epic.id, user.id)
      end
    end

    def after_create(epic)
      assign_parent_epic_for(epic)
      assign_child_epic_for(epic)
    end

    def set_date_params
      if params[:start_date_fixed] && params[:start_date_is_fixed]
        params[:start_date] = params[:start_date_fixed]
      end

      if params[:due_date_fixed] && params[:due_date_is_fixed]
        params[:end_date] = params[:due_date_fixed]
      end
    end
  end
end
