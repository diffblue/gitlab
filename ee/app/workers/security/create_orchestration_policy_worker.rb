# frozen_string_literal: true

module Security
  class CreateOrchestrationPolicyWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always
    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    feature_category :security_policy_management

    def perform
      Security::OrchestrationPolicyConfiguration.with_outdated_configuration.each_batch do |configurations|
        configurations.each do |configuration|
          Security::SyncScanPoliciesWorker.perform_async(configuration.id)
        end
      end
    end
  end
end
