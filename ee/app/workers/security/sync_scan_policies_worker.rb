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
      configuration = Security::OrchestrationPolicyConfiguration.find_by_id(configuration_id)

      return unless configuration

      update_policy_configuration(configuration)
    end
  end
end
