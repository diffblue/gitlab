# frozen_string_literal: true

module GitlabSubscriptions
  module Trials
    class ApplyTrialWorker
      include ApplicationWorker

      ApplyTrialError = Class.new(StandardError)

      deduplicate :until_executed
      data_consistency :delayed
      idempotent!
      # this worker calls `GitlabSubscriptions::ApplyTrialService`, which in turn makes
      # a HTTP POST request to ::Gitlab::SubscriptionPortal::SUBSCRIPTIONS_URL
      worker_has_external_dependencies!

      feature_category :purchase

      def perform(current_user_id, trial_user_information)
        result = GitlabSubscriptions::ApplyTrialService.new.execute(uid: current_user_id,
                                                                    trial_user: trial_user_information)

        return if result[:success]

        logger.error(
          structured_payload(
            params: { uid: current_user_id, trial_user: trial_user_information },
            message: result[:errors]
          )
        )

        raise ApplyTrialError
      end
    end
  end
end
