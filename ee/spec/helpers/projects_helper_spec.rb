# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectsHelper do
  let_it_be_with_refind(:project) { create(:project) }

  before do
    helper.instance_variable_set(:@project, project)
  end

  describe 'default_clone_protocol' do
    context 'when gitlab.config.kerberos is enabled and user is logged in' do
      it 'returns krb5 as default protocol' do
        allow(Gitlab.config.kerberos).to receive(:enabled).and_return(true)
        allow(helper).to receive(:current_user).and_return(double)

        expect(helper.send(:default_clone_protocol)).to eq('krb5')
      end
    end
  end

  describe '#can_update_security_orchestration_policy_project?' do
    let(:owner) { project.owner }

    before do
      allow(helper).to receive(:current_user) { owner }
    end

    it 'returns false when user cannot update security orchestration policy project' do
      allow(helper).to receive(:can?).with(owner, :update_security_orchestration_policy_project, project) { false }
      expect(helper.can_update_security_orchestration_policy_project?(project)).to eq false
    end

    it 'returns true when user can update security orchestration policy project' do
      allow(helper).to receive(:can?).with(owner, :update_security_orchestration_policy_project, project) { true }
      expect(helper.can_update_security_orchestration_policy_project?(project)).to eq true
    end
  end

  describe '#can_import_members?' do
    let(:owner) { project.owner }

    before do
      allow(helper).to receive(:current_user) { owner }
    end

    it 'returns false if membership is locked' do
      allow(helper).to receive(:membership_locked?) { true }
      expect(helper.can_import_members?).to eq false
    end

    it 'returns true if membership is not locked' do
      allow(helper).to receive(:membership_locked?) { false }
      expect(helper.can_import_members?).to eq true
    end
  end

  describe '#show_compliance_framework_badge?' do
    it 'returns false if compliance framework setting is not present' do
      expect(helper.show_compliance_framework_badge?(project)).to be_falsey
    end

    it 'returns true if compliance framework setting is present' do
      project = build_stubbed(:project, :with_compliance_framework)

      expect(helper.show_compliance_framework_badge?(project)).to be_truthy
    end
  end

  describe '#membership_locked?' do
    let(:project) { build_stubbed(:project, group: group) }
    let(:group) { nil }

    context 'when project has no group' do
      let(:project) { Project.new }

      it 'is false' do
        expect(helper).not_to be_membership_locked
      end
    end

    context 'with group_membership_lock enabled' do
      let(:group) { build_stubbed(:group, membership_lock: true) }

      it 'is true' do
        expect(helper).to be_membership_locked
      end
    end

    context 'with global LDAP membership lock enabled' do
      before do
        stub_application_setting(lock_memberships_to_ldap: true)
      end

      context 'and group membership_lock disabled' do
        let(:group) { build_stubbed(:group, membership_lock: false) }

        it 'is true' do
          expect(helper).to be_membership_locked
        end
      end
    end
  end

  describe '#group_project_templates_count' do
    let_it_be(:user) { create(:user) }
    let_it_be(:parent_group) { create(:group, name: 'parent-group') }
    let_it_be(:template_group) { create(:group, parent: parent_group, name: 'template-group') }
    let_it_be(:template_project) { create(:project, group: template_group, name: 'template-project') }

    before_all do
      parent_group.update!(custom_project_templates_group_id: template_group.id)
      parent_group.add_owner(user)
    end

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    specify do
      expect(helper.group_project_templates_count(parent_group.id)).to eq 1
    end

    context 'when template project is pending deletion' do
      before do
        template_project.update!(marked_for_deletion_at: Date.current)
      end

      specify do
        expect(helper.group_project_templates_count(parent_group.id)).to eq 0
      end
    end
  end

  describe '#project_security_dashboard_config' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :repository, group: group) }
    let_it_be(:jira_integration) { create(:jira_integration, project: project, vulnerabilities_enabled: true, project_key: 'GV', vulnerabilities_issuetype: '10000') }

    subject { helper.project_security_dashboard_config(project) }

    before do
      group.add_owner(user)
      stub_licensed_features(jira_vulnerabilities_integration: true)
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_return(true)
    end

    context 'project without vulnerabilities' do
      let(:expected_value) do
        {
          has_vulnerabilities: 'false',
          has_jira_vulnerabilities_integration_enabled: 'true',
          empty_state_svg_path: start_with('/assets/illustrations/security-dashboard_empty'),
          survey_request_svg_path: start_with('/assets/illustrations/security-dashboard_empty'),
          security_dashboard_help_path: '/help/user/application_security/security_dashboard/index',
          project_full_path: project.full_path,
          no_vulnerabilities_svg_path: start_with('/assets/illustrations/issues-'),
          security_configuration_path: end_with('/configuration')
        }
      end

      it { is_expected.to match(expected_value) }
    end

    context 'project with vulnerabilities' do
      let(:base_values) do
        {
          has_vulnerabilities: 'true',
          has_jira_vulnerabilities_integration_enabled: 'true',
          project: { id: project.id, name: project.name },
          project_full_path: project.full_path,
          vulnerabilities_export_endpoint: "/api/v4/security/projects/#{project.id}/vulnerability_exports",
          no_vulnerabilities_svg_path: start_with('/assets/illustrations/issues-'),
          empty_state_svg_path: start_with('/assets/illustrations/security-dashboard-empty-state'),
          survey_request_svg_path: start_with('/assets/illustrations/security-dashboard_empty'),
          dashboard_documentation: '/help/user/application_security/security_dashboard/index',
          security_dashboard_help_path: '/help/user/application_security/security_dashboard/index',
          not_enabled_scanners_help_path: help_page_path('user/application_security/index', anchor: 'quick-start'),
          no_pipeline_run_scanners_help_path: "/#{project.full_path}/-/pipelines/new",
          auto_fix_documentation: help_page_path('user/application_security/index', anchor: 'auto-fix-merge-requests'),
          auto_fix_mrs_path: end_with('/merge_requests?label_name=GitLab-auto-fix'),
          scanners: '[{"id":123,"vendor":"Security Vendor","report_type":"SAST"}]',
          can_admin_vulnerability: 'true'
        }
      end

      before do
        create(:vulnerability, project: project)
        scanner = create(:vulnerabilities_scanner, project: project, id: 123)
        create(:vulnerabilities_finding, project: project, scanner: scanner)
      end

      context 'without pipeline' do
        before do
          allow(project).to receive(:latest_pipeline_with_security_reports).and_return(nil)
        end

        it { is_expected.to match(base_values) }
      end

      context 'with pipeline' do
        let(:pipeline_created_at) { '1881-05-19T00:00:00Z' }
        let(:pipeline) { build_stubbed(:ci_pipeline, project: project, created_at: pipeline_created_at) }
        let(:pipeline_values) do
          {
            pipeline: {
              id: pipeline.id,
              path: "/#{project.full_path}/-/pipelines/#{pipeline.id}",
              created_at: pipeline_created_at,
              security_builds: {
                failed: {
                  count: 0,
                  path: "/#{project.full_path}/-/pipelines/#{pipeline.id}/failures"
                }
              }
            }
          }
        end

        before do
          allow(project).to receive(:latest_pipeline_with_security_reports).and_return(pipeline)
        end

        it { is_expected.to match(base_values.merge!(pipeline_values)) }
      end
    end
  end

  describe '#show_discover_project_security?' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:user) { create(:user) }

    where(
      gitlab_com?: [true, false],
      user?: [true, false],
      security_dashboard_feature_available?: [true, false],
      can_admin_namespace?: [true, false]
    )

    with_them do
      it 'returns the expected value' do
        allow(::Gitlab).to receive(:com?) { gitlab_com? }
        allow(helper).to receive(:current_user) { user? ? user : nil }
        allow(project).to receive(:feature_available?) { security_dashboard_feature_available? }
        allow(helper).to receive(:can?) { can_admin_namespace? }

        expected_value = user? && gitlab_com? && !security_dashboard_feature_available? && can_admin_namespace?

        expect(helper.show_discover_project_security?(project)).to eq(expected_value)
      end
    end
  end

  describe '#remove_project_message' do
    subject { helper.remove_project_message(project) }

    before do
      allow(project).to receive(:adjourned_deletion?).and_return(enabled)
    end

    context 'when project has delayed deletion enabled' do
      let(:enabled) { true }

      specify do
        deletion_date = helper.permanent_deletion_date(Time.now.utc)

        expect(subject).to eq "Deleting a project places it into a read-only state until #{deletion_date}, at which point the project will be permanently deleted. Are you ABSOLUTELY sure?"
      end
    end

    context 'when project has delayed deletion disabled' do
      let(:enabled) { false }

      specify do
        expect(subject).to eq "You are going to delete #{project.full_name}. Deleted projects CANNOT be restored! Are you ABSOLUTELY sure?"
      end
    end
  end

  describe '#scheduled_for_deletion?' do
    context 'when project is NOT scheduled for deletion' do
      it { expect(helper.scheduled_for_deletion?(project)).to be false }
    end

    context 'when project is scheduled for deletion' do
      let_it_be(:archived_project) { create(:project, :archived, marked_for_deletion_at: 10.minutes.ago) }

      it { expect(helper.scheduled_for_deletion?(archived_project)).to be true }
    end
  end

  describe '#project_permissions_settings' do
    using RSpec::Parameterized::TableSyntax

    let(:expected_settings) { { requirementsAccessLevel: 20, securityAndComplianceAccessLevel: 10 } }

    subject { helper.project_permissions_settings(project) }

    it { is_expected.to include(expected_settings) }

    context 'cveIdRequestEnabled' do
      context "with cve_id_request_button feature flag" do
        where(feature_flag_enabled: [true, false])
        with_them do
          before do
            stub_feature_flags(cve_id_request_button: feature_flag_enabled)
          end

          it 'includes cveIdRequestEnabled' do
            expect(subject.key?(:cveIdRequestEnabled)).to eq(feature_flag_enabled)
          end
        end
      end

      where(:project_attrs, :cve_enabled, :expected) do
        [:public]   | true  | true
        [:public]   | false | false
        [:internal] | true  | false
        [:private]  | true  | false
      end
      with_them do
        let(:project) { create(:project, :with_cve_request, *project_attrs, cve_request_enabled: cve_enabled) }
        subject { helper.project_permissions_settings(project) }

        it 'has the correct cveIdRequestEnabled value' do
          expect(subject[:cveIdRequestEnabled]).to eq(expected)
        end
      end
    end
  end

  describe '#project_permissions_panel_data' do
    using RSpec::Parameterized::TableSyntax

    let(:user) { instance_double(User, admin?: false) }
    let(:expected_data) { { requirementsAvailable: false } }

    subject { helper.project_permissions_panel_data(project) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_return(false)
    end

    it { is_expected.to include(expected_data) }

    context "if in Gitlab.com" do
      where(is_gitlab_com: [true, false])
      with_them do
        before do
          allow(Gitlab).to receive(:com?).and_return(is_gitlab_com)
        end

        it 'sets requestCveAvailable to the correct value' do
          expect(subject[:requestCveAvailable]).to eq(is_gitlab_com)
        end
      end
    end

    context "with cve_id_request_button feature flag" do
      where(feature_flag_enabled: [true, false])
      with_them do
        before do
          stub_feature_flags(cve_id_request_button: feature_flag_enabled)
        end

        it 'includes requestCveAvailable' do
          expect(subject.key?(:requestCveAvailable)).to eq(feature_flag_enabled)
        end
      end
    end
  end

  describe '#approvals_app_data' do
    subject { helper.approvals_app_data(project) }

    let(:user) { instance_double(User, admin?: false) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_return(true)
    end

    it 'returns the correct data' do
      expect(subject[:data]).to eq({
        project_id: project.id,
        can_edit: 'true',
        project_path: expose_path(api_v4_projects_path(id: project.id)),
        settings_path: expose_path(api_v4_projects_approval_settings_path(id: project.id)),
        rules_path: expose_path(api_v4_projects_approval_settings_rules_path(id: project.id)),
        allow_multi_rule: project.multiple_approval_rules_available?.to_s,
        eligible_approvers_docs_path: help_page_path('user/project/merge_requests/approvals/rules', anchor: 'eligible-approvers'),
        security_approvals_help_page_path: help_page_path('user/application_security/index', anchor: 'security-approvals-in-merge-requests'),
        security_configuration_path: project_security_configuration_path(project),
        vulnerability_check_help_page_path: help_page_path('user/application_security/index', anchor: 'security-approvals-in-merge-requests'),
        license_check_help_page_path: help_page_path('user/application_security/index', anchor: 'enabling-license-approvals-within-a-project'),
        coverage_check_help_page_path: help_page_path('ci/pipelines/settings', anchor: 'coverage-check-approval-rule')
      })
    end
  end

  describe '#status_checks_app_data' do
    subject { helper.status_checks_app_data(project) }

    it 'returns the correct data' do
      expect(subject[:data]).to eq({
        project_id: project.id,
        status_checks_path: expose_path(api_v4_projects_external_status_checks_path(id: project.id))
      })
    end
  end

  describe '#enable_sast_entry_points_experiment?' do
    using RSpec::Parameterized::TableSyntax

    where(
      can_admin_project?: [true, false],
      empty_repo?: [true, false],
      sast_enabled?: [true, false]
    )

    with_them do
      before do
        allow(helper).to receive(:can?) { can_admin_project? }
        allow(project).to receive(:empty_repo?) { empty_repo? }
        allow(project).to receive(:scanner_enabled?).and_call_original
        allow(OnboardingProgress).to receive(:completed?).with(project.root_ancestor, :security_scan_enabled) { sast_enabled? }
        allow(helper).to receive(:current_user) { double }
      end

      subject { helper.enable_sast_entry_points_experiment?(project) }

      it { is_expected.to eq(can_admin_project? && !empty_repo? && !sast_enabled?) }
    end
  end

  describe '#sast_entry_points_experiment_enabled?' do
    using RSpec::Parameterized::TableSyntax

    where(
      enable_sast_entry_points_experiment?: [true, false],
      experiment_enabled?: [true, false]
    )

    with_them do
      before do
        allow(helper).to receive(:enable_sast_entry_points_experiment?) { enable_sast_entry_points_experiment? }
        variant = experiment_enabled? ? :banner : :control
        stub_experiments(sast_entry_points: variant)
      end

      subject { helper.sast_entry_points_experiment_enabled?(project) }

      it { is_expected.to eq(enable_sast_entry_points_experiment? && experiment_enabled?) }
    end
  end
end
