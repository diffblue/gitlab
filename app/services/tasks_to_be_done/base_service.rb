# frozen_string_literal: true

module TasksToBeDone
  class BaseService < ::IssuableBaseService
    def initialize(project:, current_user:, assignee_ids:)
      params = {
        assignee_ids: assignee_ids,
        title: title,
        description: description
      }
      super(project: project, current_user: current_user, params: params)
    end

    def execute
      if (issue = existing_task_issue)
        update_service = Issues::UpdateService.new(project: project, current_user: current_user, params: { add_assignee_ids: params[:assignee_ids] })
        update_service.execute(issue)
      else
        build_service = Issues::BuildService.new(project: project, current_user: current_user, params: params)
        create(build_service.execute)
      end
    end

    private

    def existing_task_issue
      project.issues.opened.where(title: params[:title]).last # rubocop: disable CodeReuse/ActiveRecord
    end
  end
end
