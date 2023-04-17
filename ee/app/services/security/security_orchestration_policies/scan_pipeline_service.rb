# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class ScanPipelineService
      SCAN_VARIABLES = {
        secret_detection: {
          'SECRET_DETECTION_HISTORIC_SCAN' => 'false'
        }
      }.freeze

      attr_reader :project, :base_variables

      def initialize(project = nil, base_variables = SCAN_VARIABLES)
        @project = project
        @base_variables = base_variables
      end

      def execute(actions)
        actions = actions.select do |action|
          valid_scan_type?(action[:scan]) && pipeline_scan_type?(action[:scan].to_s)
        end

        on_demand_scan_actions, other_actions = actions.partition do |action|
          on_demand_scan_type?(action[:scan].to_s)
        end

        pipeline_scan_config = other_actions.map.with_index do |action, index|
          prepare_policy_configuration(action, index)
        end.reduce({}, :merge)

        on_demand_config = prepare_on_demand_policy_configuration(on_demand_scan_actions)

        { pipeline_scan: pipeline_scan_config,
          on_demand: on_demand_config }
      end

      private

      def pipeline_scan_type?(scan_type)
        scan_type.in?(Security::ScanExecutionPolicy::PIPELINE_SCAN_TYPES)
      end

      def on_demand_scan_type?(scan_type)
        scan_type.in?(Security::ScanExecutionPolicy::ON_DEMAND_SCANS)
      end

      def valid_scan_type?(scan_type)
        Security::ScanExecutionPolicy.valid_scan_type?(scan_type)
      end

      def prepare_on_demand_policy_configuration(actions)
        return {} if actions.blank?

        Security::SecurityOrchestrationPolicies::OnDemandScanPipelineConfigurationService
          .new(project)
          .execute(actions)
      end

      def prepare_policy_configuration(action, index)
        action_variables = action[:variables].to_h.stringify_keys

        ::Security::SecurityOrchestrationPolicies::CiConfigurationService
          .new
          .execute(action, action_variables.merge(scan_variables(action)), index)
          .deep_symbolize_keys
      end

      def scan_variables(action)
        base_variables[action[:scan].to_sym].to_h
      end
    end
  end
end
