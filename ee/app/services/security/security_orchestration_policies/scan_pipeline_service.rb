# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class ScanPipelineService
      SCAN_VARIABLES = {
        secret_detection: {
          'SECRET_DETECTION_HISTORIC_SCAN' => 'false',
          'SECRET_DETECTION_DISABLED' => nil
        },
        container_scanning: {
          'CONTAINER_SCANNING_DISABLED' => nil
        }
      }.freeze

      def execute(actions)
        actions.map.with_index do |action, index|
          valid_scan_type?(action[:scan]) ? prepare_policy_configuration(action, index) : {}
        end.reduce({}, :merge)
      end

      private

      def valid_scan_type?(scan_type)
        Security::ScanExecutionPolicy.valid_scan_type?(scan_type)
      end

      def prepare_policy_configuration(action, index)
        {
          "#{action[:scan].dasherize}-#{index}" => scan_configuration(action)
        }.deep_symbolize_keys
      end

      def scan_configuration(action)
        ::Security::SecurityOrchestrationPolicies::CiConfigurationService.new.execute(action, scan_variables(action))
      end

      def scan_variables(action)
        case action[:scan].to_sym
        when :cluster_image_scan
          ClusterImageScanningCiVariablesService.new(project: project).execute(action).first
        else
          SCAN_VARIABLES[action[:scan].to_sym].to_h
        end
      end
    end
  end
end
