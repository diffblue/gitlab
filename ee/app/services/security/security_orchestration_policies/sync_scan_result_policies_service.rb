# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class SyncScanResultPoliciesService
      def initialize(configuration)
        @configuration = configuration
      end

      def execute
        if configuration.namespace? && Feature.disabled?(:group_level_scan_result_policies, configuration.namespace)
          configuration.delete_scan_finding_rules
          return
        end

        projects.find_each do |project|
          Security::ProcessScanResultPolicyWorker.perform_async(project.id, configuration.id)
        end
      end

      private

      attr_reader :configuration

      def projects
        @projects ||= if configuration.namespace?
                        configuration.namespace.all_projects
                      else
                        Project.id_in(configuration.project_id)
                      end
      end
    end
  end
end
