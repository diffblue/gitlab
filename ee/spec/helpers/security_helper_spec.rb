# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SecurityHelper do
  describe '#instance_security_dashboard_data' do
    let_it_be(:group) { create(:group) }
    let_it_be(:has_group) { true }
    let_it_be(:project) { create(:project, namespace: group) }

    let_it_be(:current_user) { create(:user) }
    let_it_be(:expected_can_admin_vulnerability) { 'true' }

    before do
      stub_licensed_features(security_dashboard: true)
      project.namespace.add_maintainer(current_user) if has_group
      create(:users_security_dashboard_project, user: current_user, project: project)
    end

    subject { instance_security_dashboard_data }

    it 'returns vulnerability, project, feedback, asset, and docs paths for the instance security dashboard' do
      is_expected.to eq({
        no_vulnerabilities_svg_path: image_path('illustrations/issues.svg'),
        empty_state_svg_path: image_path('illustrations/operations-dashboard_empty.svg'),
        security_dashboard_empty_svg_path: image_path('illustrations/security-dashboard_empty.svg'),
        project_add_endpoint: security_projects_path,
        project_list_endpoint: security_projects_path,
        instance_dashboard_settings_path: settings_security_dashboard_path,
        vulnerabilities_export_endpoint: api_v4_security_vulnerability_exports_path,
        can_admin_vulnerability: expected_can_admin_vulnerability,
        scanners: '[]',
        false_positive_doc_url: help_page_path('user/application_security/vulnerabilities/index'),
        can_view_false_positive: 'false',
        has_projects: 'true'
      })
    end

    context 'can_admin_vulnerability' do
      subject { instance_security_dashboard_data[:can_admin_vulnerability] }

      context 'when user is not an auditor' do
        let_it_be(:current_user) { create(:user) }

        context 'when the user has admin priveledges on all projects requested' do
          it 'can_admin_vulnerability is true' do
            is_expected.to eq(expected_can_admin_vulnerability)
          end
        end

        context 'when the user does not have admin priveledges on all projects requested' do
          let_it_be(:expected_can_admin_vulnerability) { 'false' }
          let_it_be(:project2) { create(:project, namespace: group) }

          before do
            project2.namespace.add_guest(current_user) if has_group
            create(:users_security_dashboard_project, user: current_user, project: project2)
          end

          it 'can_admin_vulnerability is false' do
            is_expected.to eq(expected_can_admin_vulnerability)
          end
        end

        context 'when the project is on a personal namespace' do
          let_it_be(:project) { create(:project, creator: current_user) }
          let_it_be(:has_group) { false }

          before do
            create(:project_authorization, user: current_user, project: project, access_level: Gitlab::Access::OWNER)
          end

          it 'can_admin_vulnerability is true' do
            is_expected.to eq(expected_can_admin_vulnerability)
          end
        end
      end

      context 'when user is auditor' do
        let_it_be(:current_user) { create(:user, :auditor) }
        let_it_be(:expected_can_admin_vulnerability) { 'false' }

        it 'can_admin_vulnerability is false' do
          is_expected.to eq(expected_can_admin_vulnerability)
        end
      end
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
