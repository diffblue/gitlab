# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class CreatePipelineService < ::BaseProjectService
      SCAN_VARIABLES = {
        'secret_detection' => {
          'SECRET_DETECTION_HISTORIC_SCAN' => 'true',
          'SECRET_DETECTION_DISABLED' => nil
        }
      }.freeze

      def execute
        service = Ci::CreatePipelineService.new(project, current_user, ref: params[:branch])
        result = service.execute(:security_orchestration_policy, content: ci_configuration.to_yaml)

        pipeline = result.payload
        if pipeline.created_successfully?
          success(payload: pipeline)
        else
          error(pipeline.full_error_messages)
        end
      end

      private

      def ci_configuration
        ci_content = ::Security::SecurityOrchestrationPolicies::CiConfigurationService.new.execute(action, SCAN_VARIABLES[scan_type])

        { "#{scan_type}" => ci_content }
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
