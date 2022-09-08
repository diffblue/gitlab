# frozen_string_literal: true

module Security
  class SyncScanPoliciesWorker
    include ApplicationWorker
    include UpdateOrchestrationPolicyConfiguration

    data_consistency :always

    sidekiq_options retry: true

    idempotent!

    feature_category :security_policy_management

    def perform(configuration_id)
      configuration = Security::OrchestrationPolicyConfiguration.find(configuration_id)
      update_policy_configuration(configuration)
    end
  end
end
