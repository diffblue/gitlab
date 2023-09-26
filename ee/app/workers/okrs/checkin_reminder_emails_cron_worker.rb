# frozen_string_literal: true

module Okrs
  class CheckinReminderEmailsCronWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency

    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    feature_category :team_planning

    def initialize(date: Date.today)
      @date = date
      @day  = date.day
    end

    def perform
      frequencies.each do |frequency|
        Okrs::CheckinReminderKeyResultFinder.new(frequency, @date).execute.find_in_batches.each do |key_results|
          key_results.each do |key_result|
            project = key_result.project

            next unless ::Feature.enabled?(:okr_checkin_reminders, project)

            assignees = key_result.assignees

            assignees.each do |assignee|
              Notify.okr_checkin_reminder_notification(
                user: assignee,
                work_item: key_result,
                project: project
              ).deliver_later
            end

            progress = key_result.progress || key_result.build_progress
            progress.update(last_reminder_sent_at: Time.now.utc)
          end
        end
      end
    end

    def frequencies
      list = []
      list << 'weekly' if tuesday?
      list << 'twice_monthly' if first_or_third_tuesday?
      list << 'monthly' if first_tuesday?
      list
    end

    private

    def tuesday?
      @date.tuesday?
    end

    def first_or_third_tuesday?
      first_tuesday? || (@date.tuesday? && @day >= 15 && @day <= 21)
    end

    def first_tuesday?
      @date.tuesday? && @day <= 7
    end
  end
end
