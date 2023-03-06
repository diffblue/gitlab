# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class SyncScanResultPoliciesProjectService
      def initialize(configuration)
        @configuration = configuration
      end

      def execute(project_id)
        Security::ProcessScanResultPolicyWorker.perform_async(project_id, configuration.id)
      end

      private

      attr_reader :configuration
    end
  end
end
