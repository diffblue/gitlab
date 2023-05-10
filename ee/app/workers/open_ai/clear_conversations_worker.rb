# frozen_string_literal: true

module OpenAi
  class ClearConversationsWorker
    # We can only keep open ai data for 90 days
    # We run this as a cron job twice a day to clear out old conversation messages
    include ApplicationWorker

    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    idempotent!
    feature_category :not_owned # rubocop:disable Gitlab/AvoidFeatureCategoryNotOwned
    data_consistency :sticky
    deduplicate :until_executed, including_scheduled: true
    urgency :low

    # We can only keep open ai data for 90 days, expire earlier in case of issues
    EXPIRATION_DURATION = 80.days
    BATCH_SIZE = 100

    def perform
      runtime_limiter = Analytics::CycleAnalytics::RuntimeLimiter.new(4.minutes)

      klasses = [
        Ci::Editor::AiConversation::Message
      ]

      # rubocop:disable CodeReuse/ActiveRecord
      klasses.each do |klass|
        loop do
          break if runtime_limiter.over_time?

          sleep 0.01 # prevent overloading the DBs
          delete_count = klass
            .where('created_at <= ?', EXPIRATION_DURATION.ago)
            .limit(BATCH_SIZE)
            .delete_all

          break if delete_count == 0
        end
      end
    end
    # rubocop:enable CodeReuse/ActiveRecord
  end
end
