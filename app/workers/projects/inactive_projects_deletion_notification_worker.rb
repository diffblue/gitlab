# frozen_string_literal: true

module Projects
  class InactiveProjectsDeletionNotificationWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker
    include ExceptionBacktrace

    data_consistency :always
    sidekiq_options retry: 3
    feature_category :source_code_management

    def perform(project_id, deletion_date)
      project = Project.find(project_id)

      notification_service.inactive_project_deletion_warning(project, deletion_date)

      update_deletion_warning_notified_projects(project_id)
    rescue ActiveRecord::RecordNotFound => error
      Gitlab::ErrorTracking.log_exception(error, project_id: project_id)
    end

    private

    def notification_service
      @notification_service ||= NotificationService.new
    end

    def update_deletion_warning_notified_projects(project_id)
      Gitlab::Redis::SharedState.with do |redis|
        redis.hset('inactive_projects_deletion_warning_email_notified', "project:#{project_id}", Date.current)
      end
    end
  end
end
