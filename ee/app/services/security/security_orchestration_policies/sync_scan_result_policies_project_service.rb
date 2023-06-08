# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class SyncScanResultPoliciesProjectService
      def initialize(configuration)
        @configuration = configuration
      end

      def execute(project_id, options = {})
        delay = options[:delay]

        if delay
          Security::ProcessScanResultPolicyWorker.perform_in(delay, project_id, configuration.id)
        else
          Security::ProcessScanResultPolicyWorker.perform_async(project_id, configuration.id)
        end
      end

      private

      attr_reader :configuration
    end
  end
end
