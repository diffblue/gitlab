# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectsHelper do
  include ::EE::GeoHelpers

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

  describe '#can_admin_project_member?' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }

    before do
      allow(helper).to receive(:current_user) { user }
      project.add_maintainer(user)
    end

    context 'when membership is not locked' do
      before do
        group.membership_lock = false
      end

      it 'returns true when membership is not locked' do
        expect(helper.can_admin_project_member?(project)).to be(true)
      end
    end

    context 'when membership is locked' do
      before do
        group.membership_lock = true
      end

      it 'returns false when membership is locked' do
        expect(helper.can_admin_project_member?(project)).to be(false)
      end
    end
  end

  describe '#show_compliance_framework_badge?' do
    context 'when feature is licensed' do
      before do
        stub_licensed_features(custom_compliance_frameworks: true)
      end

      it 'returns false if compliance framework setting is not present' do
        expect(helper.show_compliance_framework_badge?(project)).to be_falsey
      end

      it 'returns true if compliance framework setting is present' do
        project = build_stubbed(:project, :with_compliance_framework)

        expect(helper.show_compliance_framework_badge?(project)).to be_truthy
      end
    end

    context 'when feature is unlicensed' do
      before do
        stub_licensed_features(custom_compliance_frameworks: false)
      end

      it 'returns false if compliance framework setting is not present' do
        expect(helper.show_compliance_framework_badge?(project)).to be_falsey
      end

      it 'returns false if compliance framework setting is present' do
        project = build_stubbed(:project, :with_compliance_framework)

        expect(helper.show_compliance_framework_badge?(project)).to be_falsey
      end
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

    context 'with SAML membership lock enabled and group membership_lock disabled' do
      before do
        stub_application_setting(lock_memberships_to_saml: true)
      end

      let(:group) { build_stubbed(:group, membership_lock: false) }

      it 'is true' do
        expect(helper).to be_membership_locked
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
          operational_configuration_path: new_project_security_policy_path(project),
          security_dashboard_empty_svg_path: start_with('/assets/illustrations/security-dashboard_empty'),
          project_full_path: project.full_path,
          no_vulnerabilities_svg_path: start_with('/assets/illustrations/issues-'),
          security_configuration_path: end_with('/configuration'),
          can_admin_vulnerability: 'true',
          new_vulnerability_path: end_with('/security/vulnerabilities/new')
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
          operational_configuration_path: new_project_security_policy_path(project),
          security_dashboard_empty_svg_path: start_with('/assets/illustrations/security-dashboard_empty'),
          new_project_pipeline_path: "/#{project.full_path}/-/pipelines/new",
          auto_fix_mrs_path: end_with('/merge_requests?label_name=GitLab-auto-fix'),
          scanners: '[{"id":123,"vendor":"Security Vendor","report_type":"SAST"}]',
          can_admin_vulnerability: 'true',
          can_view_false_positive: 'false',
          security_configuration_path: kind_of(String),
          new_vulnerability_path: end_with('/security/vulnerabilities/new')
        }
      end

      before do
        create(:vulnerability, project: project)
        scanner = create(:vulnerabilities_scanner, project: project, id: 123)
        create(:vulnerabilities_finding, project: project, scanner: scanner)
      end

      context 'with related_url_root set' do
        let(:relative_url) { '/gitlab' }
        let(:expected_path) { "#{relative_url}/api/v4/security/projects/#{project.id}/vulnerability_exports" }

        before do
          stub_config_setting(relative_url_root: relative_url)
        end

        it { is_expected.to match(base_values.merge(vulnerabilities_export_endpoint: expected_path)) }
      end

      context 'without pipeline' do
        before do
          allow(project).to receive(:latest_ingested_security_pipeline).and_return(nil)
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
              has_warnings: 'true',
              has_errors: 'false',
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
          allow(project).to receive(:latest_ingested_security_pipeline).and_return(pipeline)
          allow(pipeline).to receive_messages(
            has_security_report_ingestion_warnings?: true,
            has_security_report_ingestion_errors?: false
          )
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

  describe '#show_ultimate_feature_removal_banner?' do
    let_it_be_with_refind(:project) { create(:project) }
    let_it_be_with_refind(:user) { create(:user) }

    context 'when the banner should be shown' do
      using RSpec::Parameterized::TableSyntax

      where(
        :feature_flag_enabled, :is_com, :is_public, :is_free, :is_member, :user_dismissed_banner,
        :legacy_open_source_license_available, :should_show_banner
      ) do
        false | false | false | false | false | true | true | false
        true  | false | false | false | false | true  | true  | false
        true  | true  | false | false | false | true  | true  | false
        true  | true  | true  | false | false | true  | true  | false
        true  | true  | true  | true  | false | true  | true  | false
        true  | true  | true  | true  | true  | true  | true  | false
        true  | true  | true  | true  | true  | false | true  | false
        true  | true  | true  | true  | true  | false | false | true
      end

      with_them do
        def dismiss_banner
          ::Users::DismissProjectCalloutService.new(
            container: nil,
            current_user: user,
            params: { project_id: project.id, feature_name: 'ultimate_feature_removal_banner' }
          ).execute
        end

        before do
          allow(helper).to receive(:current_user).and_return(user)

          stub_feature_flags(ultimate_feature_removal_banner: feature_flag_enabled)
          allow(Gitlab).to receive(:com?).and_return(is_com)
          allow(project).to receive(:public?).and_return(is_public)
          allow(project.root_namespace).to receive(:free_plan?).and_return(is_free)
          project.add_guest(user) if is_member
          dismiss_banner if user_dismissed_banner
          project.project_setting.update!(legacy_open_source_license_available: legacy_open_source_license_available)
        end

        it 'shows the banner' do
          expect(helper.show_ultimate_feature_removal_banner?(project)).to eq(should_show_banner)
        end
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

  describe '#marked_for_removal_message' do
    subject { helper.marked_for_removal_message(project) }

    before do
      allow(project).to receive(:feature_available?).with(:adjourned_deletion_for_projects_and_groups).and_return(feature_available)
    end

    context 'when project has delayed deletion feature' do
      let(:feature_available) { true }

      specify do
        deletion_date = helper.permanent_deletion_date(Time.now.utc)
        expect(subject).to eq "This action deletes <code>#{project.path_with_namespace}</code> on #{deletion_date} and everything this project contains."
      end
    end

    context 'when project does not have delayed deletion feature' do
      let(:feature_available) { false }

      specify do
        deletion_date = helper.permanent_deletion_date(Time.now.utc)
        expect(subject).to eq "This action deletes <code>#{project.path_with_namespace}</code> on #{deletion_date} and everything this project contains. <strong>There is no going back.</strong>"
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
      where(:project_attrs, :expected) do
        [:public]   | true
        [:internal] | false
        [:private]  | false
      end
      with_them do
        let(:project) { create(:project, :with_cve_request, *project_attrs) }
        subject { helper.project_permissions_settings(project) }

        it 'has the correct cveIdRequestEnabled value' do
          expect(subject[:cveIdRequestEnabled]).to eq(expected)
        end
      end
    end
  end

  describe '#project_permissions_panel_data' do
    using RSpec::Parameterized::TableSyntax

    let(:user) { instance_double(User, can_admin_all_resources?: false) }
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
  end

  describe '#approvals_app_data' do
    subject { helper.approvals_app_data(project) }

    let(:user) { instance_double(User, can_admin_all_resources?: false) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_return(true)
    end

    it 'returns the correct data' do
      expect(subject).to include(
        project_id: project.id,
        can_edit: 'true',
        can_modify_author_settings: 'true',
        can_modify_commiter_settings: 'true',
        approvals_path: expose_path(api_v4_projects_merge_request_approval_setting_path(id: project.id)),
        project_path: expose_path(api_v4_projects_path(id: project.id)),
        rules_path: expose_path(api_v4_projects_approval_rules_path(id: project.id)),
        allow_multi_rule: project.multiple_approval_rules_available?.to_s,
        eligible_approvers_docs_path: help_page_path('user/project/merge_requests/approvals/rules', anchor: 'eligible-approvers'),
        security_configuration_path: project_security_configuration_path(project),
        coverage_check_help_page_path: help_page_path('ci/pipelines/settings', anchor: 'coverage-check-approval-rule'),
        group_name: project.root_ancestor.name,
        full_path: project.full_path,
        new_policy_path: expose_path(new_project_security_policy_path(project))
      )
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

  describe '#project_compliance_framework_app_data' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }

    let(:can_edit) { false }

    subject { helper.project_compliance_framework_app_data(project, can_edit) }

    before do
      allow(helper).to receive(:image_path).and_return('#empty_state_svg_path')
    end

    context 'when the user cannot edit' do
      let(:can_edit) { false }

      it 'returns the correct data' do
        expect(subject).to eq({
          group_name: group.name,
          group_path: group_path(group),
          empty_state_svg_path: '#empty_state_svg_path'
        })
      end
    end

    context 'when the user can edit' do
      let(:can_edit) { true }

      it 'includes the framework edit path' do
        expect(subject).to eq({
          group_name: group.name,
          group_path: group_path(group),
          empty_state_svg_path: '#empty_state_svg_path',
          add_framework_path: "#{edit_group_path(group)}#js-compliance-frameworks-settings"
        })
      end
    end
  end

  describe '#remote_mirror_setting_enabled?' do
    context 'when ci_cd_projects licensed feature is enabled' do
      before do
        stub_licensed_features(ci_cd_projects: true)
      end

      context 'when there are import sources' do
        before do
          allow(Gitlab::CurrentSettings).to receive(:import_sources).and_return(["gitlab"])
        end

        context 'when application setting mirror_available is enabled' do
          before do
            stub_application_setting(mirror_available: true)
          end

          it 'is true' do
            expect(helper.remote_mirror_setting_enabled?).to be_truthy
          end
        end

        context 'when application setting mirror_available is disabled' do
          before do
            stub_application_setting(mirror_available: false)
          end

          it 'is false' do
            expect(helper.remote_mirror_setting_enabled?).to be_falsey
          end
        end
      end
    end

    context 'when ci_cd_projects licensed feature is disabled' do
      before do
        stub_licensed_features(ci_cd_projects: false)
      end

      it 'is false' do
        expect(helper.remote_mirror_setting_enabled?).to be_falsey
      end
    end
  end

  describe '#http_clone_url_to_repo' do
    let(:geo_url) { 'http://localhost/geonode_url' }
    let(:geo_node) { instance_double(GeoNode, url: geo_url) }

    subject { helper.http_clone_url_to_repo(project) }

    before do
      stub_proxied_site(geo_node)

      allow(helper).to receive(:geo_proxied_http_url_to_repo).with(geo_node, project).and_return(geo_url)
    end

    it { expect(subject).to eq geo_url }
  end

  describe '#ssh_clone_url_to_repo' do
    let(:geo_url) { 'git@localhost/geonode_url' }
    let(:geo_node) { instance_double(GeoNode, url: geo_url) }

    subject { helper.ssh_clone_url_to_repo(project) }

    before do
      stub_proxied_site(geo_node)

      allow(helper).to receive(:geo_proxied_ssh_url_to_repo).with(geo_node, project).and_return(geo_url)
    end

    it { expect(subject).to eq geo_url }
  end

  describe '#project_transfer_app_data' do
    it 'returns expected hash' do
      expect(helper.project_transfer_app_data(project)).to eq({
        full_path: project.full_path
      })
    end
  end
end
