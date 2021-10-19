# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SecurityHelper do
  describe '#instance_security_dashboard_data' do
    subject { instance_security_dashboard_data }

    let_it_be(:current_user) { create(:user) }

    it 'returns vulnerability, project, feedback, asset, and docs paths for the instance security dashboard' do
      is_expected.to eq({
        dashboard_documentation: help_page_path('user/application_security/security_dashboard/index', anchor: 'instance-security-dashboard'),
        false_positive_doc_url: help_page_path('user/application_security/vulnerabilities/index'),
        no_vulnerabilities_svg_path: image_path('illustrations/issues.svg'),
        empty_dashboard_state_svg_path: image_path('illustrations/security-dashboard-empty-state.svg'),
        empty_state_svg_path: image_path('illustrations/operations-dashboard_empty.svg'),
        operational_empty_state_svg_path: image_path('illustrations/security-dashboard_empty.svg'),
        operational_help_path: help_page_path('user/application_security/policies/index'),
        survey_request_svg_path: image_path('illustrations/security-dashboard_empty.svg'),
        project_add_endpoint: security_projects_path,
        project_list_endpoint: security_projects_path,
        instance_dashboard_settings_path: settings_security_dashboard_path,
        vulnerabilities_export_endpoint: api_v4_security_vulnerability_exports_path,
        scanners: '[]',
        can_view_false_positive: 'false'
      })
    end
  end

  describe '#instance_security_settings_data' do
    subject { instance_security_settings_data }

    context 'when user is not auditor' do
      let_it_be(:current_user) { create(:user) }

      it { is_expected.to eq({ is_auditor: "false" }) }
    end

    context 'when user is auditor' do
      let_it_be(:current_user) { create(:user, :auditor) }

      it { is_expected.to eq({ is_auditor: "true" }) }
    end
  end
end
