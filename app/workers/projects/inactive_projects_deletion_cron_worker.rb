# frozen_string_literal: true

module Projects
  class InactiveProjectsDeletionCronWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker
    include Gitlab::Utils::StrongMemoize
    include CronjobQueue

    data_consistency :always
    feature_category :source_code_management

    INTERVAL = 2.seconds.to_i

    def perform
      return unless ::Gitlab::CurrentSettings.delete_inactive_projects?

      admin_user = User.admins.humans.active.first

      notified_inactive_projects = deletion_warning_notified_projects

      Project.inactive.without_deleted.find_each(batch_size: 100).with_index do |project, index| # rubocop: disable CodeReuse/ActiveRecord
        next unless Feature.enabled?(:inactive_projects_deletion, project.root_namespace, default_enabled: :yaml)

        delay = index * INTERVAL

        with_context(project: project, user: admin_user) do
          deletion_warning_email_sent_on = notified_inactive_projects["project:#{project.id}"]

          if send_deletion_warning_email?(deletion_warning_email_sent_on, project)
            ::Projects::InactiveProjectsDeletionNotificationWorker.perform_in(delay, project.id, deletion_date)
          elsif deletion_warning_email_sent_on && delete_due_to_inactivity?(deletion_warning_email_sent_on)
            delete_redis_entry(project)
            delete_project(project, admin_user)
          end
        end
      end
    end

    private

    # Redis key 'inactive_projects_deletion_warning_email_notified' is a hash. It stores the date when the
    # deletion warning notification email was sent for an inactive project. The fields and values look like:
    # {"project:1"=>"2022-04-22", "project:5"=>"2022-04-22", "project:7"=>"2022-04-25"}
    # @return [Hash]
    def deletion_warning_notified_projects
      Gitlab::Redis::SharedState.with do |redis|
        redis.hgetall('inactive_projects_deletion_warning_email_notified')
      end
    end

    def grace_months_after_deletion_notification
      strong_memoize(:grace_months_after_deletion_notification) do
        (::Gitlab::CurrentSettings.inactive_projects_delete_after_months -
          ::Gitlab::CurrentSettings.inactive_projects_send_warning_email_after_months).months
      end
    end

    def send_deletion_warning_email?(deletion_warning_email_sent_on, project)
      deletion_warning_email_sent_on.blank?
    end

    def delete_due_to_inactivity?(deletion_warning_email_sent_on)
      deletion_warning_email_sent_on < grace_months_after_deletion_notification.ago
    end

    def deletion_date
      grace_months_after_deletion_notification.from_now.to_date.to_s
    end

    def delete_project(project, user)
      ::Projects::DestroyService.new(project, user, {}).async_execute
    end

    def delete_redis_entry(project)
      Gitlab::Redis::SharedState.with do |redis|
        redis.hdel('inactive_projects_deletion_warning_email_notified', "project:#{project.id}")
      end
    end
  end
end

Projects::InactiveProjectsDeletionCronWorker.prepend_mod
