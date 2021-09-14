# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class CreatePipelineService < ::BaseProjectService
      SCAN_VARIABLES = {
        'secret_detection' => {
          'SECRET_DETECTION_HISTORIC_SCAN' => 'true',
          'SECRET_DETECTION_DISABLED' => nil
        },
        'container_scanning' => {
          'CONTAINER_SCANNING_DISABLED' => nil
        }
      }.freeze

      def execute
        service = Ci::CreatePipelineService.new(project, current_user, ref: params[:branch])
        ci_content, ci_hidden_variables = ci_configuration
        result = service.execute(:security_orchestration_policy, content: ci_content.to_yaml, variables_attributes: ci_hidden_variables)

        pipeline = result.payload
        if pipeline.created_successfully?
          success(payload: pipeline)
        else
          error(pipeline.full_error_messages)
        end
      end

      private

      def ci_configuration
        ci_variables, ci_hidden_variables = scan_variables
        ci_content = ::Security::SecurityOrchestrationPolicies::CiConfigurationService.new.execute(action, ci_variables)

        [{ "#{scan_type}" => ci_content }, ci_hidden_variables]
      end

      def scan_variables
        case scan_type.to_sym
        when :cluster_image_scanning
          ClusterImageScanningCiVariablesService.new(project: project).execute(action)
        else
          [SCAN_VARIABLES[scan_type].to_h, []]
        end
      end

      def action
        params[:action]
      end

      def scan_type
        action[:scan]
      end
    end
  end
end
