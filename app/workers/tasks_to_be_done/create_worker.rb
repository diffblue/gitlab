# frozen_string_literal: true

module TasksToBeDone
  class CreateWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    idempotent!
    feature_category :onboarding
    urgency :low
    worker_resource_boundary :cpu

    def perform(project_id, current_user_id, assignee_ids, tasks_to_be_done)
      project = Project.find(project_id)
      current_user = User.find(current_user_id)

      tasks_to_be_done.each do |task|
        service_class(task)
          .new(project: project, current_user: current_user, assignee_ids: assignee_ids)
          .execute
      end
    end

    private

    def service_class(task)
      "TasksToBeDone::Create#{task.to_s.camelize}TaskService".constantize
    end
  end
end
