# frozen_string_literal: true

module Emails
  class AbandonedTrialEmailsCronWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    feature_category :onboarding

    ACTIVITIES_DELAY = 10.days.ago
    # Search for abandoned trials 11 days ago to allow first day activities
    TRIAL_STARTED_DELAY = ACTIVITIES_DELAY - 1.day

    def perform
      Group.with_trial_started_on(TRIAL_STARTED_DELAY).find_each do |group|
        next if Event.for_projects_after(
          Project.for_group_and_its_subgroups(group),
          ACTIVITIES_DELAY
        ).exists?

        group.members
             .active_without_invites_and_requests
             .all_by_access_level(Member::OWNER)
             .select(:id, :user_id)
             .find_each do |member|
          Notify.abandoned_trial_notification(member.user_id).deliver_later
        end
      end
    end
  end
end
