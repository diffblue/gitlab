# frozen_string_literal: true

module GitlabSubscriptions
  module Trials
    class ApplyTrialWorker
      include ApplicationWorker

      ApplyTrialError = Class.new(StandardError)

      deduplicate :until_executed
      data_consistency :always
      idempotent!
      # this worker calls `GitlabSubscriptions::Trials::ApplyTrialService`, which in turn makes
      # a HTTP POST request to ::Gitlab::SubscriptionPortal::SUBSCRIPTIONS_URL
      worker_has_external_dependencies!

      feature_category :purchase

      def perform(current_user_id, trial_user_information)
        service = GitlabSubscriptions::Trials::ApplyTrialService
                    .new(uid: current_user_id, trial_user_information: trial_user_information.deep_symbolize_keys)
        result = service.execute

        return if result.success?

        logger.error(
          structured_payload(
            params: { uid: current_user_id, trial_user_information: trial_user_information },
            message: result.errors
          )
        )

        raise ApplyTrialError if service.valid_to_generate_trial?
      end
    end
  end
end
