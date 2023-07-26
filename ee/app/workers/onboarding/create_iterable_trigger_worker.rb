# frozen_string_literal: true

module Onboarding
  class CreateIterableTriggerWorker
    include ApplicationWorker

    CreateIterableTriggerError = Class.new(StandardError)

    deduplicate :until_executed
    data_consistency :delayed

    idempotent!
    # this worker calls `Onboarding::CreateIterableTriggerService`, which in turn makes
    # a HTTP POST request to ::Gitlab::SubscriptionPortal::SUBSCRIPTIONS_URL
    worker_has_external_dependencies!

    feature_category :onboarding

    def perform(iterable_params)
      result = ::Onboarding::CreateIterableTriggerService.new.execute(iterable_params)
      return if result.success?

      logger.error(
        structured_payload(
          params: { iterable_params: iterable_params },
          message: result.errors
        )
      )

      raise CreateIterableTriggerError
    end
  end
end
