# frozen_string_literal: true

module Security
  class OrchestrationConfigurationCreateBotWorker
    include ApplicationWorker

    feature_category :security_policy_management

    data_consistency :sticky

    idempotent!

    def perform(configuration_id, current_user_id)
      configuration = Security::OrchestrationPolicyConfiguration.find_by_id(configuration_id)

      return if configuration.nil?

      current_user = User.find_by_id(current_user_id)

      return unless current_user

      Security::Orchestration::CreateBotService.new(configuration, current_user).execute
    rescue Gitlab::Access::AccessDeniedError,
      Security::Orchestration::CreateBotService::SecurityOrchestrationPolicyConfigurationHasNoProjectError
      # Rescue errors to avoid worker retry
    end
  end
end
