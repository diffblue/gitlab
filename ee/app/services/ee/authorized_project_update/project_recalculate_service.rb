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

        Security::ScanResultPolicies::SyncProjectWorker.perform_in(1.minute, project.id)
      end
    end
  end
end
