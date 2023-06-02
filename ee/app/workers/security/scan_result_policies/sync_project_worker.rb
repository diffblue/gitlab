# frozen_string_literal: true

module Security
  module ScanResultPolicies
    class SyncProjectWorker
      include ApplicationWorker

      data_consistency :delayed

      deduplicate :until_executing, including_scheduled: true
      idempotent!

      feature_category :security_policy_management

      DELAY_INTERVAL = 30.seconds.to_i

      def perform(project_id)
        project = Project.find_by_id(project_id)
        return unless project

        return unless project&.licensed_feature_available?(:security_orchestration_policies)

        project.all_security_orchestration_policy_configurations.each_with_index do |configuration, index|
          Security::ProcessScanResultPolicyWorker.perform_in(index * DELAY_INTERVAL, project.id, configuration.id)
        end
      end
    end
  end
end
