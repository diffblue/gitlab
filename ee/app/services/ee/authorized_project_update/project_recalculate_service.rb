# frozen_string_literal: true

module EE
  module AuthorizedProjectUpdate
    module ProjectRecalculateService
      extend ::Gitlab::Utils::Override

      private

      override :refresh_authorizations
      def refresh_authorizations
        super

        return unless project.licensed_feature_available?(:security_orchestration_policies)
        return unless authorizations_to_create.any? { |auth| auth[:access_level] >= ::Member::DEVELOPER }

        project.all_security_orchestration_policy_configurations.each do |configuration|
          Security::ProcessScanResultPolicyWorker.perform_async(project.id, configuration.id)
        end
      end
    end
  end
end
