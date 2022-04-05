# frozen_string_literal: true

module EE
  module SecurityOrchestrationHelper
    def security_orchestration_policy_data(
      namespace,
      policy_type = nil,
      policy = nil,
      approvers = nil
    )
      return unless namespace

      {
        assigned_policy_project: 'null',
        disable_scan_policy_update: false,
        create_agent_help_path: help_page_url('user/clusters/agent/install/index'),
        policy: policy&.to_json,
        policy_editor_empty_state_svg_path: image_path('illustrations/monitoring/unable_to_connect.svg'),
        policy_type: policy_type,
        policies_path: nil,
        scan_policy_documentation_path: help_page_path('user/application_security/policies/index'),
        scan_result_approvers: approvers&.to_json
      }
    end
  end
end
