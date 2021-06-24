# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Project do
  include ProjectForksHelper
  include ::EE::GeoHelpers
  using RSpec::Parameterized::TableSyntax

  let(:project) { create(:project) }

  describe 'associations' do
    it { is_expected.to delegate_method(:shared_runners_minutes).to(:statistics) }
    it { is_expected.to delegate_method(:shared_runners_seconds).to(:statistics) }
    it { is_expected.to delegate_method(:shared_runners_seconds_last_reset).to(:statistics) }

    it { is_expected.to delegate_method(:ci_minutes_quota).to(:shared_runners_limit_namespace) }
    it { is_expected.to delegate_method(:shared_runners_minutes_limit_enabled?).to(:shared_runners_limit_namespace) }

    it { is_expected.to delegate_method(:closest_gitlab_subscription).to(:namespace) }

    it { is_expected.to delegate_method(:pipeline_configuration_full_path).to(:compliance_management_framework) }

    it { is_expected.to delegate_method(:prevent_merge_without_jira_issue).to(:project_setting) }

    it { is_expected.to belong_to(:deleting_user) }

    it { is_expected.to have_one(:import_state).class_name('ProjectImportState') }
    it { is_expected.to have_one(:repository_state).class_name('ProjectRepositoryState').inverse_of(:project) }
    it { is_expected.to have_one(:push_rule).inverse_of(:project) }
    it { is_expected.to have_one(:status_page_setting).class_name('StatusPage::ProjectSetting') }
    it { is_expected.to have_one(:compliance_framework_setting).class_name('ComplianceManagement::ComplianceFramework::ProjectSettings') }
    it { is_expected.to have_one(:compliance_management_framework).class_name('ComplianceManagement::Framework') }
    it { is_expected.to have_one(:security_setting).class_name('ProjectSecuritySetting') }
    it { is_expected.to have_one(:vulnerability_statistic).class_name('Vulnerabilities::Statistic') }
    it { is_expected.to have_one(:security_orchestration_policy_configuration).class_name('Security::OrchestrationPolicyConfiguration').inverse_of(:project) }

    it { is_expected.to have_many(:path_locks) }
    it { is_expected.to have_many(:vulnerability_feedback) }
    it { is_expected.to have_many(:vulnerability_exports) }
    it { is_expected.to have_many(:vulnerability_scanners) }
    it { is_expected.to have_many(:dast_site_profiles) }
    it { is_expected.to have_many(:dast_site_tokens) }
    it { is_expected.to have_many(:dast_sites) }
    it { is_expected.to have_many(:audit_events).dependent(false) }
    it { is_expected.to have_many(:protected_environments) }
    it { is_expected.to have_many(:approvers).dependent(:destroy) }
    it { is_expected.to have_many(:approver_users).through(:approvers) }
    it { is_expected.to have_many(:approver_groups).dependent(:destroy) }
    it { is_expected.to have_many(:upstream_project_subscriptions) }
    it { is_expected.to have_many(:upstream_projects) }
    it { is_expected.to have_many(:downstream_project_subscriptions) }
    it { is_expected.to have_many(:downstream_projects) }
    it { is_expected.to have_many(:vulnerability_historical_statistics).class_name('Vulnerabilities::HistoricalStatistic') }
    it { is_expected.to have_many(:vulnerability_remediations).class_name('Vulnerabilities::Remediation') }

    it { is_expected.to have_one(:github_integration) }
    it { is_expected.to have_many(:project_aliases) }
    it { is_expected.to have_many(:approval_rules) }

    it { is_expected.to have_many(:incident_management_oncall_schedules).class_name('IncidentManagement::OncallSchedule') }
    it { is_expected.to have_many(:incident_management_oncall_rotations).through(:incident_management_oncall_schedules).source(:rotations) }
    it { is_expected.to have_many(:incident_management_escalation_policies).class_name('IncidentManagement::EscalationPolicy') }

    include_examples 'ci_cd_settings delegation'

    describe '#merge_pipelines_enabled?' do
      it_behaves_like 'a ci_cd_settings predicate method' do
        let(:delegated_method) { :merge_pipelines_enabled? }
      end
    end

    describe '#merge_pipelines_were_disabled?' do
      it_behaves_like 'a ci_cd_settings predicate method' do
        let(:delegated_method) { :merge_pipelines_were_disabled? }
      end
    end

    describe '#merge_trains_enabled?' do
      it_behaves_like 'a ci_cd_settings predicate method' do
        let(:delegated_method) { :merge_trains_enabled? }
      end
    end

    describe '#auto_rollback_enabled?' do
      it_behaves_like 'a ci_cd_settings predicate method' do
        let(:delegated_method) { :auto_rollback_enabled? }
      end
    end

    describe '#jira_vulnerabilities_integration_enabled?' do
      context 'when project lacks a jira_integration relation' do
        it 'returns false' do
          expect(project.jira_vulnerabilities_integration_enabled?).to be false
        end
      end

      context 'when project has a jira_integration relation' do
        before do
          create(:jira_integration, project: project)
        end

        it 'accesses the value from the jira_integration' do
          expect(project.jira_integration)
            .to receive(:jira_vulnerabilities_integration_enabled?)

          project.jira_vulnerabilities_integration_enabled?
        end
      end
    end

    describe '#configured_to_create_issues_from_vulnerabilities?' do
      context 'when project lacks a jira_integration relation' do
        it 'returns false' do
          expect(project.configured_to_create_issues_from_vulnerabilities?).to be false
        end
      end

      context 'when project has a jira_integration relation' do
        before do
          create(:jira_integration, project: project)
        end

        it 'accesses the value from the jira_integration' do
          expect(project.jira_integration)
            .to receive(:configured_to_create_issues_from_vulnerabilities?)

          project.configured_to_create_issues_from_vulnerabilities?
        end
      end
    end

    describe '#jira_issue_association_required_to_merge_enabled?' do
      before do
        stub_licensed_features(
          jira_issues_integration: jira_integration_licensed,
          jira_issue_association_enforcement: jira_enforcement_licensed
        )

        project.build_jira_integration(active: jira_integration_active)
        stub_feature_flags(jira_issue_association_on_merge_request: feature_flag)
      end

      where(
        jira_integration_licensed: [true, false],
        jira_integration_active: [true, false],
        jira_enforcement_licensed: [true, false],
        feature_flag: [true, false]
      )

      with_them do
        it 'is enabled if all values are true' do
          expect(project.jira_issue_association_required_to_merge_enabled?).to be(
            jira_integration_licensed && jira_integration_active && jira_enforcement_licensed && feature_flag
          )
        end
      end
    end

    context 'import_state dependant predicate method' do
      shared_examples 'returns expected values' do
        context 'when project lacks a import_state relation' do
          it 'returns false' do
            expect(project.send("mirror_#{method}")).to be_falsey
          end
        end

        context 'when project has a import_state relation' do
          before do
            create(:import_state, project: project)
          end

          it 'accesses the value from the import_state' do
            expect(project.import_state).to receive(method)

            project.send("mirror_#{method}")
          end
        end
      end

      describe '#mirror_last_update_succeeded?' do
        it_behaves_like 'returns expected values' do
          let(:method) { "last_update_succeeded?" }
        end
      end

      describe '#mirror_last_update_failed?' do
        it_behaves_like 'returns expected values' do
          let(:method) { "last_update_failed?" }
        end
      end

      describe '#mirror_ever_updated_successfully?' do
        it_behaves_like 'returns expected values' do
          let(:method) { "ever_updated_successfully?" }
        end
      end
    end

    describe 'approval_rules association' do
      let_it_be(:rule, reload: true) { create(:approval_project_rule) }

      let(:project) { rule.project }
      let(:branch) { 'stable' }

      describe '#applicable_to_branch' do
        subject { project.approval_rules.applicable_to_branch(branch) }

        context 'when there are no associated protected branches' do
          it { is_expected.to eq([rule]) }
        end

        context 'when there are associated protected branches' do
          before do
            rule.update!(protected_branches: protected_branches)
          end

          context 'and branch matches' do
            let(:protected_branches) { [create(:protected_branch, name: branch)] }

            it { is_expected.to eq([rule]) }
          end

          context 'but branch does not match anything' do
            let(:protected_branches) { [create(:protected_branch, name: branch.reverse)] }

            it { is_expected.to be_empty }
          end
        end
      end

      describe '#inapplicable_to_branch' do
        subject { project.approval_rules.inapplicable_to_branch(branch) }

        context 'when there are no associated protected branches' do
          it { is_expected.to be_empty }
        end

        context 'when there are associated protected branches' do
          before do
            rule.update!(protected_branches: protected_branches)
          end

          context 'and branch does not match anything' do
            let(:protected_branches) { [create(:protected_branch, name: branch.reverse)] }

            it { is_expected.to eq([rule]) }
          end

          context 'but branch matches' do
            let(:protected_branches) { [create(:protected_branch, name: branch)] }

            it { is_expected.to be_empty }
          end
        end
      end
    end
  end

  context 'scopes' do
    describe '.requiring_code_owner_approval' do
      let!(:project) { create(:project) }
      let!(:expected_project) { protected_branch_needing_approval.project }
      let!(:protected_branch_needing_approval) { create(:protected_branch, code_owner_approval_required: true) }

      it 'only includes the right projects' do
        scoped_query_result = described_class.requiring_code_owner_approval

        expect(described_class.count).to eq(2)
        expect(scoped_query_result).to contain_exactly(expected_project)
      end
    end

    describe '.with_wiki_enabled' do
      it 'returns a project' do
        project = create(:project_empty_repo, wiki_access_level: ProjectFeature::ENABLED)
        project1 = create(:project, wiki_access_level: ProjectFeature::DISABLED)

        expect(described_class.with_wiki_enabled).to include(project)
        expect(described_class.with_wiki_enabled).not_to include(project1)
      end
    end

    describe '.github_imported' do
      it 'returns the correct project' do
        project_imported_from_github = create(:project, :github_imported)
        project_not_imported_from_github = create(:project)

        expect(described_class.github_imported).to include(project_imported_from_github)
        expect(described_class.github_imported).not_to include(project_not_imported_from_github)
      end
    end

    describe '.with_protected_branches' do
      it 'returns the correct project' do
        project_with_protected_branches = create(:project, protected_branches: [create(:protected_branch)])
        project_without_protected_branches = create(:project)

        expect(described_class.with_protected_branches).to include(project_with_protected_branches)
        expect(described_class.with_protected_branches).not_to include(project_without_protected_branches)
      end
    end

    describe '.with_repositories_enabled' do
      it 'returns the correct project' do
        project_with_repositories_enabled = create(:project, :repository_enabled)
        project_with_repositories_disabled = create(:project, :repository_disabled)

        expect(described_class.with_repositories_enabled).to include(project_with_repositories_enabled)
        expect(described_class.with_repositories_enabled).not_to include(project_with_repositories_disabled)
      end
    end

    describe '.with_github_integration_pipeline_events' do
      it 'returns the correct project' do
        project_with_github_integration_pipeline_events = create(:project, github_integration: create(:github_integration))
        project_without_github_integration_pipeline_events = create(:project)

        expect(described_class.with_github_integration_pipeline_events)
          .to include(project_with_github_integration_pipeline_events)
        expect(described_class.with_github_integration_pipeline_events)
          .not_to include(project_without_github_integration_pipeline_events)
      end
    end

    describe '.with_active_prometheus_integration' do
      it 'returns the correct project' do
        project_with_active_prometheus_integration = create(:prometheus_project)
        project_without_active_prometheus_integration = create(:project)

        expect(described_class.with_active_prometheus_integration).to include(project_with_active_prometheus_integration)
        expect(described_class.with_active_prometheus_integration).not_to include(project_without_active_prometheus_integration)
      end
    end

    describe '.with_enabled_incident_sla' do
      it 'returns the correct project' do
        project_with_enabled_incident_sla = create(:project_incident_management_setting, :sla_enabled).project
        project_without_enabled_incident_sla = create(:project_incident_management_setting).project

        expect(described_class.with_enabled_incident_sla).to include(project_with_enabled_incident_sla)
        expect(described_class.with_enabled_incident_sla).not_to include(project_without_enabled_incident_sla)
      end
    end

    describe '.has_vulnerabilities' do
      let_it_be(:project_1) { create(:project) }
      let_it_be(:project_2) { create(:project) }
      let_it_be(:project_3) { create(:project) }

      before do
        project_1.project_setting.update!(has_vulnerabilities: true)
        project_2.project_setting.update!(has_vulnerabilities: false)
      end

      subject { described_class.has_vulnerabilities }

      it { is_expected.to contain_exactly(project_1) }
    end

    describe '.has_vulnerability_statistics' do
      let_it_be(:project_1) { create(:project) }
      let_it_be(:project_2) { create(:project) }

      before do
        create(:vulnerability_statistic, project: project_1)
      end

      subject { described_class.has_vulnerability_statistics }

      it { is_expected.to contain_exactly(project_1) }
    end

    describe '.not_aimed_for_deletion' do
      let_it_be(:project) { create(:project) }
      let_it_be(:delayed_deletion_project) { create(:project, marked_for_deletion_at: Date.current) }

      it do
        expect(described_class.not_aimed_for_deletion).to contain_exactly(project)
      end
    end

    describe '.order_by_total_repository_size_excess_desc' do
      let_it_be(:project_1) { create(:project_statistics, lfs_objects_size: 10, repository_size: 10).project }
      let_it_be(:project_2) { create(:project_statistics, lfs_objects_size: 5, repository_size: 55).project }
      let_it_be(:project_3) { create(:project, repository_size_limit: 30, statistics: create(:project_statistics, lfs_objects_size: 8, repository_size: 32)) }

      let(:limit) { 20 }

      subject { described_class.order_by_total_repository_size_excess_desc(limit) }

      it { is_expected.to eq([project_2, project_3, project_1]) }
    end

    describe '.with_code_coverage' do
      let_it_be(:project_1) { create(:project) }
      let_it_be(:project_2) { create(:project) }
      let_it_be(:project_3) { create(:project) }

      let!(:coverage_1) { create(:ci_daily_build_group_report_result, project: project_1) }
      let!(:coverage_2) { create(:ci_daily_build_group_report_result, project: project_2) }

      subject { described_class.with_code_coverage }

      it { is_expected.to contain_exactly(project_1, project_2) }
    end
  end

  describe 'validations' do
    let(:project) { build(:project) }

    describe 'variables' do
      let(:first_variable) { build(:ci_variable, key: 'test_key', value: 'first', environment_scope: 'prod', project: project) }
      let(:second_variable) { build(:ci_variable, key: 'test_key', value: 'other', environment_scope: 'other', project: project) }

      before do
        project.variables << first_variable
        project.variables << second_variable
      end

      context 'with duplicate variables with same environment scope' do
        before do
          project.variables.last.environment_scope = project.variables.first.environment_scope
        end

        it { expect(project).not_to be_valid }
      end

      context 'with same variable keys and different environment scope' do
        it { expect(project).to be_valid }
      end

      it "ensures max_pages_size is an integer greater than 0 (or equal to 0 to indicate unlimited/maximum)" do
        is_expected.to validate_numericality_of(:max_pages_size).only_integer.is_greater_than_or_equal_to(0)
                         .is_less_than(::Gitlab::Pages::MAX_SIZE / 1.megabyte)
      end
    end

    context 'mirror' do
      subject { build(:project, mirror: true) }

      it { is_expected.to validate_presence_of(:import_url) }
      it { is_expected.to validate_presence_of(:mirror_user) }
    end

    it 'creates import state when mirror gets enabled' do
      project2 = create(:project)

      expect do
        project2.update(mirror: true, import_url: generate(:url), mirror_user: project.creator)
      end.to change { ProjectImportState.where(project: project2).count }.from(0).to(1)
    end
  end

  describe 'setting up a mirror' do
    context 'when new project' do
      it 'creates import_state and sets next_execution_timestamp to now' do
        project = build(:project, :mirror, creator: create(:user))

        freeze_time do
          expect do
            project.save!
          end.to change { ProjectImportState.count }.by(1)

          expect(project.import_state.next_execution_timestamp).to be_like_time(Time.current)
        end
      end
    end

    context 'when project already exists' do
      context 'when project is not import' do
        it 'creates import_state and sets next_execution_timestamp to now' do
          project = create(:project)

          freeze_time do
            expect do
              project.update(mirror: true, mirror_user_id: project.creator.id, import_url: generate(:url))
            end.to change { ProjectImportState.count }.by(1)

            expect(project.import_state.next_execution_timestamp).to be_like_time(Time.current)
          end
        end
      end

      context 'when project is import' do
        it 'sets current import_state next_execution_timestamp to now' do
          project = create(:project, import_url: generate(:url))

          freeze_time do
            expect do
              project.update(mirror: true, mirror_user_id: project.creator.id)
            end.not_to change { ProjectImportState.count }

            expect(project.import_state.next_execution_timestamp).to be_like_time(Time.current)
          end
        end
      end
    end
  end

  describe '.mirrors_to_sync' do
    let(:timestamp) { Time.current }

    context 'when mirror is scheduled' do
      it 'returns empty' do
        create(:project, :mirror, :import_scheduled)

        expect(described_class.mirrors_to_sync(timestamp)).to be_empty
      end
    end

    context 'when mirror is started' do
      it 'returns empty' do
        create(:project, :mirror, :import_scheduled)

        expect(described_class.mirrors_to_sync(timestamp)).to be_empty
      end
    end

    context 'when mirror is finished' do
      let!(:project) { create(:project) }
      let!(:import_state) { create(:import_state, :mirror, :finished, project: project) }

      it 'returns project if next_execution_timestamp is not in the future' do
        expect(described_class.mirrors_to_sync(timestamp)).to match_array(project)
      end

      it 'returns empty if next_execution_timestamp is in the future' do
        import_state.update(next_execution_timestamp: timestamp + 2.minutes)

        expect(described_class.mirrors_to_sync(timestamp)).to be_empty
      end

      context 'when a limit is applied' do
        before do
          another_project = create(:project)
          create(:import_state, :mirror, :finished, project: another_project)
        end

        it 'returns project if next_execution_timestamp is not in the future' do
          expect(described_class.mirrors_to_sync(timestamp, limit: 1)).to match_array(project)
        end
      end
    end

    context 'when project is failed' do
      let!(:project) { create(:project, :mirror, :import_failed) }

      it 'returns project if next_execution_timestamp is not in the future' do
        expect(described_class.mirrors_to_sync(timestamp)).to match_array(project)
      end

      it 'returns empty if next_execution_timestamp is in the future' do
        project.import_state.update(next_execution_timestamp: timestamp + 2.minutes)

        expect(described_class.mirrors_to_sync(timestamp)).to be_empty
      end

      context 'with retry limit exceeded' do
        let!(:project) { create(:project, :mirror, :import_hard_failed) }

        it 'returns empty' do
          expect(described_class.mirrors_to_sync(timestamp)).to be_empty
        end
      end
    end
  end

  describe '#can_store_security_reports?' do
    context 'when the feature is enabled for the namespace' do
      it 'returns true' do
        stub_licensed_features(sast: true)
        project = create(:project, :private)

        expect(project.can_store_security_reports?).to be_truthy
      end
    end

    context 'when the project is public' do
      it 'returns true' do
        stub_licensed_features(sast: false)
        project = create(:project, :public)

        expect(project.can_store_security_reports?).to be_truthy
      end
    end

    context 'when the feature is disabled for the namespace and the project is not public' do
      it 'returns false' do
        stub_licensed_features(sast: false)
        project = create(:project, :private)

        expect(project.can_store_security_reports?).to be_falsy
      end
    end
  end

  describe '#deployment_variables' do
    let(:project) { create(:project) }

    let!(:default_cluster) do
      create(:cluster,
              :not_managed,
              platform_type: :kubernetes,
              projects: [project],
              environment_scope: '*',
              platform_kubernetes: default_cluster_kubernetes)
    end

    let!(:review_env_cluster) do
      create(:cluster,
              :not_managed,
              platform_type: :kubernetes,
              projects: [project],
              environment_scope: 'review/*',
              platform_kubernetes: review_env_cluster_kubernetes)
    end

    let(:default_cluster_kubernetes) { create(:cluster_platform_kubernetes, token: 'default-AAA') }
    let(:review_env_cluster_kubernetes) { create(:cluster_platform_kubernetes, token: 'review-AAA') }

    context 'when environment name is review/name' do
      let!(:environment) { create(:environment, project: project, name: 'review/name') }

      it 'returns variables from this service' do
        expect(project.deployment_variables(environment: 'review/name'))
          .to include(key: 'KUBE_TOKEN', value: 'review-AAA', public: false, masked: true)
      end
    end

    context 'when environment name is other' do
      let!(:environment) { create(:environment, project: project, name: 'staging/name') }

      it 'returns variables from this service' do
        expect(project.deployment_variables(environment: 'staging/name'))
          .to include(key: 'KUBE_TOKEN', value: 'default-AAA', public: false, masked: true)
      end
    end
  end

  describe '#ensure_external_webhook_token' do
    let(:project) { create(:project, :repository) }

    it "sets external_webhook_token when it's missing" do
      project.update_attribute(:external_webhook_token, nil)
      expect(project.external_webhook_token).to be_blank

      project.ensure_external_webhook_token
      expect(project.external_webhook_token).to be_present
    end
  end

  describe '#push_rule' do
    let(:project) { create(:project, push_rule: create(:push_rule)) }

    subject(:push_rule) { project.reload_push_rule }

    it { is_expected.not_to be_nil }

    context 'push rules unlicensed' do
      before do
        stub_licensed_features(push_rules: false)
      end

      it { is_expected.to be_nil }
    end
  end

  context 'merge requests related settings' do
    shared_examples 'setting modified by application setting' do
      where(:feature_enabled, :app_setting, :project_setting, :final_setting) do
        true  | true  | true  | true
        true  | false | true  | true
        true  | true  | false | true
        true  | false | false | false
        false | true  | true  | true
        false | false | true  | true
        false | true  | false | false
        false | false | false | false
      end

      with_them do
        let(:project) { create(:project) }

        before do
          stub_licensed_features(admin_merge_request_approvers_rules: feature_enabled)

          stub_application_setting(application_setting => app_setting)
          project.update(setting => project_setting)
        end

        it 'shows proper setting' do
          expect(project.send(setting)).to eq(final_setting)
          expect(project.send("#{setting}?")).to eq(final_setting)
        end
      end
    end

    describe '#disable_overriding_approvers_per_merge_request' do
      it_behaves_like 'setting modified by application setting' do
        let(:setting) { :disable_overriding_approvers_per_merge_request }
        let(:application_setting) { :disable_overriding_approvers_per_merge_request }
      end
    end

    shared_examples 'a predicate wrapper method' do
      where(:wrapped_method_return, :subject_return) do
        true  | true
        false | false
        nil   | false
      end

      with_them do
        it 'returns the expected boolean value' do
          expect(project)
            .to receive(wrapped_method)
            .and_return(wrapped_method_return)

          expect(project.send("#{wrapped_method}?")).to be(subject_return)
        end
      end
    end

    describe '#disable_overriding_approvers_per_merge_request?' do
      it_behaves_like 'a predicate wrapper method' do
        let(:wrapped_method) { :disable_overriding_approvers_per_merge_request }
      end
    end

    describe '#merge_requests_disable_committers_approval' do
      it_behaves_like 'setting modified by application setting' do
        let(:setting) { :merge_requests_disable_committers_approval }
        let(:application_setting) { :prevent_merge_requests_committers_approval }
      end
    end

    describe '#merge_requests_disable_committers_approval?' do
      it_behaves_like 'a predicate wrapper method' do
        let(:wrapped_method) { :merge_requests_disable_committers_approval }
      end
    end

    describe '#require_password_to_approve?' do
      it_behaves_like 'a predicate wrapper method' do
        let(:wrapped_method) { :require_password_to_approve }
      end
    end

    describe '#merge_requests_author_approval' do
      let(:setting) { :merge_requests_author_approval }
      let(:application_setting) { :prevent_merge_requests_author_approval }

      where(:feature_enabled, :app_setting, :project_setting, :final_setting) do
        true  | true  | true  | false
        true  | false | true  | true
        true  | true  | false | false
        true  | false | false | false
        false | true  | true  | true
        false | false | true  | true
        false | true  | false | false
        false | false | false | false
      end

      with_them do
        let(:project) { create(:project) }

        before do
          stub_licensed_features(admin_merge_request_approvers_rules: feature_enabled)

          stub_application_setting(application_setting => app_setting)
          project.update(setting => project_setting)
        end

        it 'shows proper setting' do
          expect(project.send(setting)).to eq(final_setting)
          expect(project.send("#{setting}?")).to eq(final_setting)
        end
      end
    end

    describe '#merge_requests_author_approval?' do
      it_behaves_like 'a predicate wrapper method' do
        let(:wrapped_method) { :merge_requests_author_approval }
      end
    end
  end

  describe '#has_active_hooks?' do
    context "with group hooks" do
      let(:group) { create(:group) }
      let(:project) { create(:project, namespace: group) }
      let!(:group_hook) { create(:group_hook, group: group, push_events: true) }

      before do
        stub_licensed_features(group_webhooks: true)
      end

      it 'returns true' do
        expect(project.has_active_hooks?).to be_truthy
        expect(project.has_group_hooks?).to be_truthy
      end
    end

    context 'with no group hooks' do
      it 'returns false' do
        expect(project.has_active_hooks?).to be_falsey
        expect(project.has_group_hooks?).to be_falsey
      end
    end
  end

  describe '#has_group_hooks?' do
    subject { project.has_group_hooks? }

    let(:project) { create(:project) }

    it { is_expected.to eq(nil) }

    context 'project is in a group' do
      let(:group) { create(:group) }
      let(:project) { create(:project, namespace: group) }

      shared_examples 'returns nil when the feature is not available' do
        specify do
          stub_licensed_features(group_webhooks: false)

          expect(subject).to eq(nil)
        end
      end

      it_behaves_like 'returns nil when the feature is not available'

      it { is_expected.to eq(false) }

      context 'the group has hooks' do
        let!(:group_hook) { create(:group_hook, group: group, push_events: true) }

        it { is_expected.to eq(true) }

        it_behaves_like 'returns nil when the feature is not available'

        context 'but the hook is not in scope' do
          subject { project.has_group_hooks?(:issue_hooks) }

          it_behaves_like 'returns nil when the feature is not available'

          it { is_expected.to eq(false) }
        end
      end

      context 'the group inherits a hook' do
        let(:parent_group) { create(:group) }
        let!(:group_hook) { create(:group_hook, group: parent_group) }
        let(:group) { create(:group, parent: parent_group) }

        it_behaves_like 'returns nil when the feature is not available'

        it { is_expected.to eq(true) }
      end
    end
  end

  describe '#execute_external_compliance_hooks' do
    let_it_be(:rule) { create(:external_status_check) }

    it 'enqueues the correct number of workers' do
      allow(rule).to receive(:async_execute).once

      rule.project.execute_external_compliance_hooks({})
    end
  end

  describe "#execute_hooks" do
    context "group hooks" do
      let(:group) { create(:group) }
      let(:project) { create(:project, namespace: group) }
      let(:group_hook) { create(:group_hook, group: group, push_events: true) }

      it 'does not execute the hook when the feature is disabled' do
        stub_licensed_features(group_webhooks: false)

        expect(WebHookService).not_to receive(:new)
                                        .with(group_hook, { some: 'info' }, 'push_hooks')

        project.execute_hooks(some: 'info')
      end

      context 'when group_webhooks feature is enabled' do
        before do
          stub_licensed_features(group_webhooks: true)
        end
        let(:fake_integration) { double }

        shared_examples 'triggering group webhook' do
          it 'executes the hook' do
            expect(fake_integration).to receive(:async_execute).once

            expect(WebHookService)
              .to receive(:new).with(group_hook, { some: 'info' }, 'push_hooks') { fake_integration }

            project.execute_hooks(some: 'info')
          end
        end

        it_behaves_like 'triggering group webhook'

        context 'in sub group' do
          let(:sub_group) { create :group, parent: group }
          let(:sub_sub_group) { create :group, parent: sub_group }
          let(:project) { create(:project, namespace: sub_sub_group) }

          it_behaves_like 'triggering group webhook'
        end
      end
    end
  end

  describe '#allowed_to_share_with_group?' do
    let(:project) { create(:project) }

    it "returns true" do
      expect(project.allowed_to_share_with_group?).to be_truthy
    end

    it "returns false" do
      project.namespace.update(share_with_group_lock: true)
      expect(project.allowed_to_share_with_group?).to be_falsey
    end
  end

  describe '#feature_available?' do
    let(:namespace) { build(:namespace) }
    let(:plan_license) { nil }
    let(:project) { build(:project, namespace: namespace) }
    let(:user) { build(:user) }

    subject { project.feature_available?(feature, user) }

    context 'when feature symbol is included on Namespace features code' do
      before do
        stub_application_setting('check_namespace_plan?' => check_namespace_plan)
        allow(Gitlab).to receive(:com?) { true }
        stub_licensed_features(feature => allowed_on_global_license)
        allow(namespace).to receive(:plan) { plan_license }
      end

      License::EEU_FEATURES.each do |feature_sym|
        context feature_sym.to_s do
          let(:feature) { feature_sym }

          unless License::GLOBAL_FEATURES.include?(feature_sym)
            context "checking #{feature_sym} availability both on Global and Namespace license" do
              let(:check_namespace_plan) { true }

              context 'allowed by Plan License AND Global License' do
                let(:allowed_on_global_license) { true }
                let(:plan_license) { build(:ultimate_plan) }

                before do
                  allow(namespace).to receive(:plans) { [plan_license] }
                end

                it 'returns true' do
                  is_expected.to eq(true)
                end
              end

              context 'not allowed by Plan License but project and namespace are public' do
                let(:allowed_on_global_license) { true }
                let(:plan_license) { build(:bronze_plan) }

                it 'returns true' do
                  allow(namespace).to receive(:public?) { true }
                  allow(project).to receive(:public?) { true }

                  is_expected.to eq(true)
                end
              end

              unless License.plan_includes_feature?(License::STARTER_PLAN, feature_sym)
                context 'not allowed by Plan License' do
                  let(:allowed_on_global_license) { true }
                  let(:plan_license) { build(:bronze_plan) }

                  it 'returns false' do
                    is_expected.to eq(false)
                  end
                end
              end

              context 'not allowed by Global License' do
                let(:allowed_on_global_license) { false }
                let(:plan_license) { build(:ultimate_plan) }

                it 'returns false' do
                  is_expected.to eq(false)
                end
              end
            end
          end

          context "when checking #{feature_sym} only for Global license" do
            let(:check_namespace_plan) { false }

            context 'allowed by Global License' do
              let(:allowed_on_global_license) { true }

              it 'returns true' do
                is_expected.to eq(true)
              end
            end

            context 'not allowed by Global License' do
              let(:allowed_on_global_license) { false }

              it 'returns false' do
                is_expected.to eq(false)
              end
            end
          end
        end
      end
    end

    it 'only loads licensed availability once' do
      expect(project).to receive(:load_licensed_feature_available)
        .once.and_call_original

      with_license_feature_cache do
        2.times { project.feature_available?(:push_rules) }
      end
    end

    context 'when feature symbol is not included on Namespace features code' do
      let(:feature) { :issues }

      it 'checks availability of licensed feature' do
        expect(project.project_feature).to receive(:feature_available?).with(feature, user)

        subject
      end
    end
  end

  describe '#fetch_mirror' do
    where(:import_url, :auth_method, :expected) do
      'http://foo:bar@example.com' | 'password'       | 'http://foo:bar@example.com'
      'ssh://foo:bar@example.com'  | 'password'       | 'ssh://foo:bar@example.com'
      'ssh://foo:bar@example.com'  | 'ssh_public_key' | 'ssh://foo@example.com'
    end

    with_them do
      let(:project) { build(:project, :mirror, import_url: import_url, import_data_attributes: { auth_method: auth_method } ) }

      specify do
        expect(project.repository).to receive(:fetch_upstream).with(expected, forced: false, check_tags_changed: false)

        project.fetch_mirror
      end
    end
  end

  describe 'updating import_url' do
    it 'removes previous remote' do
      project = create(:project, :repository, :mirror)

      expect(RepositoryRemoveRemoteWorker).to receive(:perform_async).with(project.id, ::Repository::MIRROR_REMOTE).and_call_original

      project.update(import_url: "http://test.com")
    end
  end

  describe '#any_online_runners?' do
    let!(:shared_runner) { create(:ci_runner, :instance, :online) }

    it { expect(project.any_online_runners?).to be_truthy }

    context 'with used pipeline minutes' do
      let(:namespace) { create(:namespace, :with_used_build_minutes_limit) }
      let(:project) do
        create(:project,
               namespace: namespace,
               shared_runners_enabled: true)
      end

      it 'does not have any online runners' do
        expect(project.any_online_runners?).to be_falsey
      end
    end
  end

  describe '#shared_runners_available?' do
    subject { project.shared_runners_available? }

    context 'with used pipeline minutes' do
      let(:namespace) { create(:namespace, :with_used_build_minutes_limit) }
      let(:project) do
        create(:project,
          namespace: namespace,
          shared_runners_enabled: true)
      end

      it 'shared runners are not available' do
        expect(project.shared_runners_available?).to be_falsey
      end
    end

    context 'without used pipeline minutes' do
      let(:namespace) { create(:namespace, :with_not_used_build_minutes_limit) }
      let(:project) do
        create(:project,
          namespace: namespace,
          shared_runners_enabled: true)
      end

      it 'shared runners are not available' do
        expect(project.shared_runners_available?).to be_truthy
      end
    end
  end

  describe '#root_namespace' do
    let(:project) { build(:project, namespace: parent) }

    subject { project.root_namespace }

    context 'when namespace has parent group' do
      let(:root_ancestor) { create(:group) }
      let(:parent) { create(:group, parent: root_ancestor) }

      it 'returns root ancestor' do
        is_expected.to eq(root_ancestor)
      end
    end

    context 'when namespace is root ancestor' do
      let(:parent) { create(:group) }

      it 'returns current namespace' do
        is_expected.to eq(parent)
      end
    end
  end

  describe '#shared_runners_limit_namespace' do
    let_it_be(:root_ancestor) { create(:group) }
    let_it_be(:group) { create(:group, parent: root_ancestor) }

    let(:project) { create(:project, namespace: group) }

    subject { project.shared_runners_limit_namespace }

    it 'returns root namespace' do
      is_expected.to eq(root_ancestor)
    end
  end

  describe '#shared_runners_minutes_limit_enabled?' do
    let(:project) { create(:project) }

    subject { project.shared_runners_minutes_limit_enabled? }

    before do
      allow(project.namespace).to receive(:shared_runners_minutes_limit_enabled?)
        .and_return(true)
    end

    context 'with shared runners enabled' do
      before do
        project.shared_runners_enabled = true
      end

      context 'for public project' do
        before do
          project.visibility_level = Project::PUBLIC
        end

        it { is_expected.to be_truthy }
      end

      context 'for internal project' do
        before do
          project.visibility_level = Project::INTERNAL
        end

        it { is_expected.to be_truthy }
      end

      context 'for private project' do
        before do
          project.visibility_level = Project::INTERNAL
        end

        it { is_expected.to be_truthy }
      end
    end

    context 'without shared runners' do
      before do
        project.shared_runners_enabled = false
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#approvals_before_merge' do
    where(:license_value, :db_value, :expected) do
      true  | 5 | 5
      true  | 0 | 0
      false | 5 | 0
      false | 0 | 0
    end

    with_them do
      let(:project) { build(:project, approvals_before_merge: db_value) }

      subject { project.approvals_before_merge }

      before do
        stub_licensed_features(merge_request_approvers: license_value)
      end

      it { is_expected.to eq(expected) }
    end
  end

  describe "#reset_approvals_on_push?" do
    where(:license_value, :db_value, :expected) do
      true  | true  | true
      true  | false | false
      false | true  | false
      false | false | false
    end

    with_them do
      let(:project) { build(:project, reset_approvals_on_push: db_value) }

      subject { project.reset_approvals_on_push? }

      before do
        stub_licensed_features(merge_request_approvers: license_value)
      end

      it { is_expected.to eq(expected) }
    end
  end

  describe '#approvals_before_merge' do
    where(:license_value, :db_value, :expected) do
      true  | 5 | 5
      true  | 0 | 0
      false | 5 | 0
      false | 0 | 0
    end

    with_them do
      let(:project) { build(:project, approvals_before_merge: db_value) }

      subject { project.approvals_before_merge }

      before do
        stub_licensed_features(merge_request_approvers: license_value)
      end

      it { is_expected.to eq(expected) }
    end
  end

  describe '#visible_user_defined_rules' do
    let(:project) { create(:project) }
    let!(:approval_rules) { create_list(:approval_project_rule, 2, project: project) }
    let!(:any_approver_rule) { create(:approval_project_rule, rule_type: :any_approver, project: project) }
    let(:branch) { nil }

    subject { project.visible_user_defined_rules(branch: branch) }

    before do
      stub_licensed_features(multiple_approval_rules: true)
    end

    it 'returns all approval rules' do
      expect(subject).to eq([any_approver_rule, *approval_rules])
    end

    context 'when multiple approval rules is not available' do
      before do
        stub_licensed_features(multiple_approval_rules: false)
      end

      it 'returns the first approval rule' do
        expect(subject).to eq([any_approver_rule])
      end
    end

    context 'when branch is provided' do
      let(:branch) { 'master' }

      it 'caches the rules' do
        expect(project).to receive(:user_defined_rules).and_call_original
        subject

        expect(project).not_to receive(:user_defined_rules)
        subject
      end
    end
  end

  describe '#visible_user_defined_inapplicable_rules' do
    let_it_be(:project) { create(:project) }

    let!(:rule) { create(:approval_project_rule, project: project) }
    let!(:another_rule) { create(:approval_project_rule, project: project) }

    context 'when multiple approval rules is available' do
      before do
        stub_licensed_features(multiple_approval_rules: true)
      end

      let(:protected_branch) { create(:protected_branch, project: project, name: 'stable-*') }
      let(:another_protected_branch) { create(:protected_branch, project: project, name: 'test-*') }

      context 'when rules are scoped' do
        before do
          rule.update!(protected_branches: [protected_branch])
          another_rule.update!(protected_branches: [another_protected_branch])
        end

        it 'returns rules that are not applicable to target_branch' do
          expect(project.visible_user_defined_inapplicable_rules('stable-1'))
            .to match_array([another_rule])
        end
      end

      context 'when rules are not scoped' do
        it 'returns empty array' do
          expect(project.visible_user_defined_inapplicable_rules('stable-1')).to be_empty
        end
      end
    end

    context 'when multiple approval rules is not available' do
      before do
        stub_licensed_features(multiple_approval_rules: false)
      end

      it 'returns empty array' do
        expect(project.visible_user_defined_inapplicable_rules('stable-1')).to be_empty
      end
    end
  end

  describe '#min_fallback_approvals' do
    let(:project) { create(:project) }

    before do
      create(:approval_project_rule, project: project, rule_type: :any_approver, approvals_required: 2)
      create(:approval_project_rule, project: project, approvals_required: 2)
      create(:approval_project_rule, project: project, approvals_required: 3)

      stub_licensed_features(multiple_approval_rules: true)
    end

    it 'returns the maximum requirement' do
      expect(project.min_fallback_approvals).to eq(3)
    end

    it 'returns the first rule requirement if there is a rule' do
      stub_licensed_features(multiple_approval_rules: false)

      expect(project.min_fallback_approvals).to eq(2)
    end
  end

  describe '#merge_requests_require_code_owner_approval?' do
    let(:project) { build(:project) }

    where(:feature_available, :feature_enabled, :approval_required) do
      true  | true  | true
      false | true  | false
      true  | false | false
    end

    with_them do
      before do
        stub_licensed_features(code_owner_approval_required: feature_available)

        if feature_enabled
          create(:protected_branch,
            project: project,
            code_owner_approval_required: true)
        end
      end

      it 'requires code owner approval when needed' do
        expect(project.merge_requests_require_code_owner_approval?).to eq(approval_required)
      end
    end
  end

  describe '#branch_requires_code_owner_approval?' do
    let(:protected_branch) { create(:protected_branch, code_owner_approval_required: false) }
    let(:protected_branch_needing_approval) { create(:protected_branch, code_owner_approval_required: true) }

    context "when feature is enabled" do
      before do
        stub_licensed_features(code_owner_approval_required: true)
      end

      it 'returns true when code owner approval is required' do
        project = protected_branch_needing_approval.project

        expect(project.branch_requires_code_owner_approval?(protected_branch_needing_approval.name)).to eq(true)
      end

      it 'returns false when code owner approval is not required' do
        project = protected_branch.project

        expect(project.branch_requires_code_owner_approval?(protected_branch.name)).to eq(false)
      end
    end

    context "when feature is not enabled" do
      before do
        stub_licensed_features(code_owner_approval_required: false)
      end

      it 'returns true when code owner approval is required' do
        project = protected_branch_needing_approval.project

        expect(project.branch_requires_code_owner_approval?(protected_branch_needing_approval.name)).to eq(false)
      end

      it 'returns false when code owner approval is not required' do
        project = protected_branch.project

        expect(project.branch_requires_code_owner_approval?(protected_branch.name)).to eq(false)
      end
    end
  end

  describe '#disabled_integrations' do
    let(:project) { build(:project) }

    subject { project.disabled_integrations }

    where(:license_feature, :disabled_integrations) do
      :github_project_service_integration | %w[github]
    end

    with_them do
      context 'when feature is available' do
        before do
          stub_licensed_features(license_feature => true)
        end

        it { is_expected.not_to include(*disabled_integrations) }
      end

      context 'when feature is unavailable' do
        before do
          stub_licensed_features(license_feature => false)
        end

        it { is_expected.to include(*disabled_integrations) }
      end
    end
  end

  describe '#pull_mirror_available?' do
    let(:project) { create(:project) }

    context 'when mirror global setting is enabled' do
      it 'returns true' do
        expect(project.pull_mirror_available?).to be(true)
      end
    end

    context 'when mirror global setting is disabled' do
      before do
        stub_application_setting(mirror_available: false)
      end

      it 'returns true when overridden' do
        project.pull_mirror_available_overridden = true

        expect(project.pull_mirror_available?).to be(true)
      end

      it 'returns false when not overridden' do
        expect(project.pull_mirror_available?).to be(false)
      end
    end
  end

  describe '#username_only_import_url' do
    where(:import_url, :username, :expected_import_url) do
      '' | 'foo' | ''
      '' | ''    | ''
      '' | nil   | ''

      nil | 'foo' | nil
      nil | ''    | nil
      nil | nil   | nil

      'http://example.com' | 'foo' | 'http://foo@example.com'
      'http://example.com' | ''    | 'http://example.com'
      'http://example.com' | nil   | 'http://example.com'
    end

    with_them do
      let(:project) { build(:project, import_url: import_url, import_data_attributes: { user: username, password: 'password' }) }

      it { expect(project.username_only_import_url).to eq(expected_import_url) }
    end
  end

  describe '#username_only_import_url=' do
    it 'sets the import url and username' do
      project = build(:project, import_url: 'http://user@example.com')

      expect(project.import_url).to eq('http://user@example.com')
      expect(project.import_data.user).to eq('user')
    end

    it 'does not unset the password' do
      project = build(:project, import_url: 'http://olduser:pass@old.example.com')
      project.username_only_import_url = 'http://user@example.com'

      expect(project.username_only_import_url).to eq('http://user@example.com')
      expect(project.import_url).to eq('http://user:pass@example.com')
      expect(project.import_data.password).to eq('pass')
    end

    it 'clears the username if passed the empty string' do
      project = build(:project, import_url: 'http://olduser:pass@old.example.com')
      project.username_only_import_url = ''

      expect(project.username_only_import_url).to eq('')
      expect(project.import_url).to eq('')
      expect(project.import_data.user).to be_nil
      expect(project.import_data.password).to eq('pass')
    end
  end

  describe '#with_slack_application_disabled' do
    it 'returns projects where Slack application is disabled' do
      project1 = create(:project)
      project2 = create(:project)
      create(:gitlab_slack_application_integration, project: project2)

      projects = described_class.with_slack_application_disabled

      expect(projects).to include(project1)
      expect(projects).not_to include(project2)
    end
  end

  describe '#licensed_features' do
    let(:plan_license) { :free }
    let(:global_license) { create(:license) }
    let(:group) { create(:group) }
    let!(:gitlab_subscription) { create(:gitlab_subscription, plan_license, namespace: group) }
    let(:project) { create(:project, group: group) }

    before do
      allow(License).to receive(:current).and_return(global_license)
      allow(global_license).to receive(:features).and_return([
        :subepics, # Ultimate only
        :epics, # Premium and up
        :push_rules, # Premium and up
        :audit_events, # Bronze and up
        :geo # Global feature, should not be checked at namespace level
      ])
    end

    subject { project.licensed_features }

    context 'when the namespace should be checked' do
      before do
        enable_namespace_license_check!
      end

      context 'when bronze' do
        let(:plan_license) { :bronze }

        it 'filters for bronze features' do
          is_expected.to contain_exactly(:audit_events, :geo, :push_rules)
        end
      end

      context 'when premium' do
        let(:plan_license) { :premium }

        it 'filters for premium features' do
          is_expected.to contain_exactly(:push_rules, :audit_events, :geo, :epics)
        end
      end

      context 'when ultimate' do
        let(:plan_license) { :ultimate }

        it 'filters for ultimate features' do
          is_expected.to contain_exactly(:epics, :push_rules, :audit_events, :geo, :subepics)
        end
      end

      context 'when free plan' do
        let(:plan_license) { :free }

        it 'filters out paid features' do
          is_expected.to contain_exactly(:geo)
        end

        context 'when public project and namespace' do
          let(:group) { create(:group, :public) }
          let!(:gitlab_subscription) { create(:gitlab_subscription, :free, namespace: group) }
          let(:project) { create(:project, :public, group: group) }

          it 'includes all features in global license' do
            is_expected.to contain_exactly(:epics, :push_rules, :audit_events, :geo, :subepics)
          end
        end
      end
    end

    context 'when namespace should not be checked' do
      it 'includes all features in global license' do
        is_expected.to contain_exactly(:epics, :push_rules, :audit_events, :geo, :subepics)
      end
    end

    context 'when there is no license' do
      before do
        allow(License).to receive(:current).and_return(nil)
      end

      it { is_expected.to be_empty }
    end
  end

  describe '#find_path_lock' do
    let(:project) { create :project }
    let(:path_lock) { create :path_lock, project: project }
    let(:path) { path_lock.path }

    it 'returns path_lock' do
      expect(project.find_path_lock(path)).to eq(path_lock)
    end

    it 'returns nil' do
      expect(project.find_path_lock('app/controllers')).to be_falsey
    end
  end

  describe '#any_path_locks?', :request_store do
    let(:project) { create :project }

    it 'returns false when there are no path locks' do
      expect(project.any_path_locks?).to be_falsey
    end

    it 'returns a cached true when there are path locks' do
      create(:path_lock, project: project)

      expect(project.path_locks).to receive(:any?).once.and_call_original

      2.times { expect(project.any_path_locks?).to be_truthy }
    end
  end

  describe '#latest_pipeline_with_security_reports' do
    let_it_be(:project, refind: true) { create(:project) }
    let_it_be(:pipeline_1) { create(:ci_pipeline, :success, project: project) }
    let_it_be(:pipeline_2) { create(:ci_pipeline, project: project) }
    let_it_be(:pipeline_3) { create(:ci_pipeline, :success, project: project) }

    subject { project.latest_pipeline_with_security_reports(only_successful: only_successful) }

    shared_examples_for 'on-the-fly latest_pipeline_with_security_reports calculation' do |expected:|
      let(:expected_pipeline) { public_send(expected) }

      context 'when legacy reports are used' do
        before do
          create(:ee_ci_build, :legacy_sast, pipeline: pipeline_1)
          create(:ee_ci_build, :legacy_sast, pipeline: pipeline_2)
        end

        it 'returns the latest pipeline with security reports' do
          is_expected.to eq(expected_pipeline)
        end
      end

      context 'when new reports are used' do
        before do
          create(:ee_ci_build, :sast, pipeline: pipeline_1)
          create(:ee_ci_build, :sast, pipeline: pipeline_2)
        end

        it 'returns the latest pipeline with security reports' do
          is_expected.to eq(expected_pipeline)
        end

        context 'when legacy used' do
          before do
            create(:ee_ci_build, :legacy_sast, pipeline: pipeline_3)
          end

          it 'prefers the new reports' do
            is_expected.to eq(expected_pipeline)
          end
        end
      end
    end

    context 'when all pipelines are used' do
      let(:only_successful) { false }

      context 'when there is no associated `vulnerability_statistic` record with the project' do
        it_behaves_like 'on-the-fly latest_pipeline_with_security_reports calculation', expected: :pipeline_2
      end

      context 'when there is an associated `vulnerability_statistic` record with the project' do
        context 'when the pipeline of `vulnerability_statistic` has not been set' do
          it_behaves_like 'on-the-fly latest_pipeline_with_security_reports calculation', expected: :pipeline_2 do
            before do
              create(:vulnerability_statistic, project: project, pipeline: nil)
            end
          end
        end

        context 'when the pipeline of `vulnerability_statistic` has been set' do
          before do
            create(:vulnerability_statistic, project: project, pipeline: pipeline_1)
          end

          it { is_expected.to eq(pipeline_1) }
        end
      end
    end

    context 'when only successful pipelines are used' do
      let(:only_successful) { true }

      before do
        create(:vulnerability_statistic, project: project, pipeline: pipeline_2)
      end

      it_behaves_like 'on-the-fly latest_pipeline_with_security_reports calculation', expected: :pipeline_1
    end
  end

  describe '#latest_pipeline_with_reports' do
    let_it_be(:project) { create(:project) }
    let_it_be(:pipeline_1) { create(:ee_ci_pipeline, :with_sast_report, project: project) }
    let_it_be(:pipeline_2) { create(:ee_ci_pipeline, :with_sast_report, project: project) }
    let_it_be(:pipeline_3) { create(:ee_ci_pipeline, :with_dependency_scanning_report, project: project) }

    subject { project.latest_pipeline_with_reports(reports) }

    context 'when reports are found' do
      let_it_be(:reports) { ::Ci::JobArtifact.sast_reports }

      it "returns the latest pipeline with reports of right type" do
        is_expected.to eq(pipeline_2)
      end

      context 'and one of the pipelines has not yet completed' do
        let_it_be(:pipeline_4) { create(:ee_ci_pipeline, :with_sast_report, project: project, status: :running) }

        it 'returns the latest successful pipeline with reports' do
          is_expected.to eq(pipeline_2)
        end
      end
    end

    context 'when reports are not found' do
      let(:reports) { ::Ci::JobArtifact.metrics_reports }

      it 'returns nothing' do
        is_expected.to be_nil
      end
    end
  end

  describe '#security_reports_up_to_date_for_ref?' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:merge_request) do
      create(:ee_merge_request,
             source_project: project,
             source_branch: 'feature1',
             target_branch: project.default_branch)
    end

    let_it_be(:pipeline) do
      create(:ee_ci_pipeline,
             :with_sast_report,
             project: project,
             ref: merge_request.target_branch)
    end

    subject { project.security_reports_up_to_date_for_ref?(merge_request.target_branch) }

    context 'when the target branch security reports are up to date' do
      it { is_expected.to be true }
    end

    context 'when the target branch security reports are out of date' do
      let_it_be(:bad_pipeline) { create(:ee_ci_pipeline, :failed, project: project, ref: merge_request.target_branch) }

      it { is_expected.to be false }
    end
  end

  describe '#after_import' do
    let_it_be(:project) { create(:project) }

    context 'Geo repository update events' do
      let_it_be(:import_state) { create(:import_state, :started, project: project) }

      let(:repository_updated_service) { instance_double('::Geo::RepositoryUpdatedService') }
      let(:wiki_updated_service) { instance_double('::Geo::RepositoryUpdatedService') }
      let(:design_updated_service) { instance_double('::Geo::RepositoryUpdatedService') }

      before do
        allow(::Geo::RepositoryUpdatedService)
          .to receive(:new)
          .with(project.repository)
          .and_return(repository_updated_service)

        allow(::Geo::RepositoryUpdatedService)
          .to receive(:new)
          .with(project.wiki.repository)
          .and_return(wiki_updated_service)

        allow(::Geo::RepositoryUpdatedService)
          .to receive(:new)
          .with(project.design_repository)
          .and_return(design_updated_service)
      end

      it 'calls Geo::RepositoryUpdatedService when running on a Geo primary node', :aggregate_failures do
        stub_primary_node

        expect(repository_updated_service).to receive(:execute).once
        expect(wiki_updated_service).to receive(:execute).once
        expect(design_updated_service).to receive(:execute).once

        project.after_import
      end

      it 'does not call Geo::RepositoryUpdatedService when not running on a Geo primary node', :aggregate_failures do
        expect(repository_updated_service).not_to receive(:execute)
        expect(wiki_updated_service).not_to receive(:execute)
        expect(design_updated_service).not_to receive(:execute)

        project.after_import
      end
    end

    context 'elasticsearch indexing' do
      let_it_be(:import_state) { create(:import_state, project: project) }

      context 'elasticsearch indexing disabled for this project' do
        before do
          expect(project).to receive(:use_elasticsearch?).and_return(false)
        end

        it 'does not index the wiki repository' do
          expect(ElasticCommitIndexerWorker).not_to receive(:perform_async)

          project.after_import
        end
      end

      context 'elasticsearch indexing enabled for this project' do
        before do
          expect(project).to receive(:use_elasticsearch?).and_return(true)
        end

        it 'schedules a full index of the wiki repository' do
          expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(project.id, true)

          project.after_import
        end

        context 'when project is forked' do
          before do
            expect(project).to receive(:forked?).and_return(true)
          end

          it 'does not index the wiki repository' do
            expect(ElasticCommitIndexerWorker).not_to receive(:perform_async)

            project.after_import
          end
        end
      end
    end
  end

  describe '#lfs_http_url_to_repo' do
    let(:project) { create(:project) }
    let(:project_path) { "#{Gitlab::Routing.url_helpers.project_path(project)}.git" }

    let(:primary_base_host) { 'primary.geo' }
    let(:primary_base_url) { "http://#{primary_base_host}" }
    let(:primary_url) { "#{primary_base_url}#{project_path}" }

    context 'with a Geo setup that is a primary' do
      let(:primary_node) { create(:geo_node, url: primary_base_url) }

      before do
        stub_current_geo_node(primary_node)
        stub_default_url_options(primary_base_host)
      end

      context 'for an upload operation' do
        it 'returns the project HTTP URL for the primary' do
          expect(project.lfs_http_url_to_repo('upload')).to eq(primary_url)
        end
      end
    end

    context 'with a Geo setup that is a secondary' do
      let(:secondary_base_host) { 'secondary.geo' }
      let(:secondary_base_url) { "http://#{secondary_base_host}" }
      let(:secondary_node) { create(:geo_node, url: secondary_base_url) }
      let(:secondary_url) { "#{secondary_base_url}#{project_path}" }

      before do
        stub_current_geo_node(secondary_node)
        stub_default_url_options(current_rails_hostname)
      end

      context 'and has a primary' do
        let(:primary_node) { create(:geo_node, url: primary_base_url) }

        context 'for an upload operation' do
          let(:current_rails_hostname) { primary_base_host }

          it 'returns the project HTTP URL for the primary' do
            expect(project.lfs_http_url_to_repo('upload')).to eq(primary_url)
          end
        end

        context 'for a download operation' do
          let(:current_rails_hostname) { secondary_base_host }

          it 'returns the project HTTP URL for the secondary' do
            expect(project.lfs_http_url_to_repo('download')).to eq(secondary_url)
          end
        end
      end

      context 'without a primary' do
        let(:current_rails_hostname) { secondary_base_host }

        it 'returns the project HTTP URL for the secondary' do
          expect(project.lfs_http_url_to_repo('operation_that_doesnt_matter')).to eq(secondary_url)
        end
      end
    end

    context 'without a Geo setup' do
      it 'returns the project HTTP URL for the main node' do
        project_url = "#{Gitlab::Routing.url_helpers.project_url(project)}.git"

        expect(project.lfs_http_url_to_repo('operation_that_doesnt_matter')).to eq(project_url)
      end
    end
  end

  describe '#add_import_job' do
    let(:project) { create(:project) }

    before do
      stub_licensed_features(custom_project_templates: true)
    end

    context 'when import_type is gitlab_custom_project_template' do
      it 'does not create import job' do
        project.import_type = 'gitlab_custom_project_template'

        expect(project.gitlab_custom_project_template_import?).to be true
        expect(project.add_import_job).to be_nil
      end
    end

    context 'when mirror true on a jira imported project' do
      let_it_be(:user) { create(:user) }
      let_it_be(:project) { create(:project, :repository, import_type: 'jira', mirror: true, import_url: 'http://some_url.com', mirror_user_id: user.id) }
      let_it_be(:jira_import) { create(:jira_import_state, project: project) }

      context 'when jira import is in progress' do
        before do
          jira_import.start
        end

        it 'does trigger mirror update' do
          expect(RepositoryUpdateMirrorWorker).to receive(:perform_async)
          expect(Gitlab::JiraImport::Stage::StartImportWorker).not_to receive(:perform_async)
          expect(project.mirror).to be true
          expect(project.jira_import?).to be true

          project.add_import_job
        end
      end
    end
  end

  describe '#gitlab_custom_project_template_import?' do
    let(:project) { create(:project, import_type: 'gitlab_custom_project_template') }

    context 'when licensed' do
      before do
        stub_licensed_features(custom_project_templates: true)
      end

      it 'returns true' do
        expect(project.gitlab_custom_project_template_import?).to be true
      end
    end

    context 'when unlicensed' do
      it 'returns false' do
        expect(project.gitlab_custom_project_template_import?).to be false
      end
    end
  end

  describe '#feature_flags_client_token' do
    let(:project) { create(:project) }

    subject { project.feature_flags_client_token }

    context 'when there is no access token' do
      it "creates a new one" do
        is_expected.not_to be_empty
      end
    end

    context 'when there is access token' do
      let(:token_encrypted) { Gitlab::CryptoHelper.aes256_gcm_encrypt('token') }
      let!(:instance) { create(:operations_feature_flags_client, project: project, token_encrypted: token_encrypted) }

      it "provides an existing one" do
        is_expected.to eq('token')
      end
    end
  end

  describe '#has_pool_repository?' do
    it 'returns false when there is no pool repository' do
      project = create(:project)

      expect(project.has_pool_repository?).to be false
    end

    it 'returns true when there is a pool repository' do
      pool = create(:pool_repository, :ready)
      project = create(:project, pool_repository: pool)

      expect(project.has_pool_repository?).to be true
    end
  end

  describe '#link_pool_repository' do
    let(:project) { create(:project, :repository) }

    subject  { project.link_pool_repository }

    it 'logs geo event' do
      expect(project.repository).to receive(:log_geo_updated_event)

      subject
    end
  end

  describe '#object_pool_missing?' do
    let(:pool) { create(:pool_repository, :ready) }

    subject { create(:project, :repository, pool_repository: pool) }

    it 'returns true when object pool is missing' do
      allow(pool.object_pool).to receive(:exists?).and_return(false)

      expect(subject.object_pool_missing?).to be true
    end

    it "returns false when pool repository doesnt't exist" do
      allow(subject).to receive(:has_pool_repository?).and_return(false)

      expect(subject.object_pool_missing?).to be false
    end

    it 'returns false when object pool exists' do
      expect(subject.object_pool_missing?).to be false
    end
  end

  describe "#insights_config" do
    context 'when project has no Insights config file' do
      let(:project) { create(:project) }

      it 'returns the project default config' do
        expect(project.insights_config).to eq(project.default_insights_config)
      end

      context 'when the project is inside a group' do
        let(:group) { create(:group) }
        let(:project) { create(:project, group: group) }

        context 'when the group has no Insights config' do
          it 'returns the group default config' do
            expect(project.insights_config).to eq(group.default_insights_config)
          end
        end

        context 'when the group has an Insights config from another project' do
          let(:config_project) do
            create(:project, :custom_repo, group: group, files: { ::Gitlab::Insights::CONFIG_FILE_PATH => insights_file_content })
          end

          before do
            group.create_insight!(project: config_project)
          end

          context 'with a valid config file' do
            let(:insights_file_content) { 'key: monthlyBugsCreated' }

            it 'returns the group config data from the other project' do
              expect(project.insights_config).to eq(config_project.insights_config)
              expect(project.insights_config).to eq(group.insights_config)
            end

            context 'when the project is inside a nested group' do
              let(:nested_group) { create(:group, parent: group) }
              let(:project) { create(:project, group: nested_group) }

              # The following expectaction should be changed to
              # expect(project.insights_config).to eq(config_project.insights_config)
              # once https://gitlab.com/gitlab-org/gitlab/issues/11340 is implemented.
              it 'returns the project default config' do
                expect(project.insights_config).to eq(project.default_insights_config)
              end
            end
          end

          context 'with an invalid config file' do
            let(:insights_file_content) { ': foo bar' }

            it 'returns nil' do
              expect(project.insights_config).to be_nil
            end
          end
        end
      end
    end

    context 'when project has an Insights config file' do
      let(:project) do
        create(:project, :custom_repo, files: { ::Gitlab::Insights::CONFIG_FILE_PATH => insights_file_content })
      end

      context 'with a valid config file' do
        let(:insights_file_content) { 'key: monthlyBugsCreated' }

        it 'returns the insights config data' do
          expect(project.insights_config).to eq(key: 'monthlyBugsCreated')
        end

        context 'when the project is inside a group having another config' do
          let(:group) { create(:group) }
          let(:config_project) do
            create(:project, :custom_repo, group: group, files: { ::Gitlab::Insights::CONFIG_FILE_PATH => ': foo bar' })
          end

          before do
            project.group = group
            project.group.create_insight!(project: config_project)
          end

          it 'returns the project insights config data' do
            expect(project.insights_config).to eq(key: 'monthlyBugsCreated')
          end
        end
      end

      context 'with an invalid config file' do
        let(:insights_file_content) { ': foo bar' }

        it 'returns nil' do
          expect(project.insights_config).to be_nil
        end

        context 'when the project is inside a group having another config' do
          let(:group) { create(:group) }
          let(:config_project) do
            create(:project, :custom_repo, group: group, files: { ::Gitlab::Insights::CONFIG_FILE_PATH => 'key: monthlyBugsCreated' })
          end

          before do
            project.group = group
            project.group.create_insight!(project: config_project)
          end

          it 'returns nil' do
            expect(project.insights_config).to be_nil
          end
        end
      end
    end
  end

  describe "#kerberos_url_to_repo" do
    let(:project) { create(:project, path: "somewhere") }

    it 'returns valid kerberos url for this repo' do
      expect(project.kerberos_url_to_repo).to eq("#{Gitlab.config.build_gitlab_kerberos_url}/#{project.namespace.path}/somewhere.git")
    end
  end

  describe '#actual_size_limit' do
    context 'when repository_size_limit is set on the project' do
      it 'returns the repository_size_limit' do
        project = build(:project, repository_size_limit: 10)

        expect(project.actual_size_limit).to eq(10)
      end
    end

    context 'when repository_size_limit is not set on the project' do
      it 'returns the actual_size_limit of the namespace' do
        group = build(:group, repository_size_limit: 20)
        project = build(:project, namespace: group, repository_size_limit: nil)

        expect(project.actual_size_limit).to eq(20)
      end
    end
  end

  describe '#repository_size_checker' do
    let(:project) { build(:project) }
    let(:checker) { project.repository_size_checker }

    describe '#current_size' do
      let(:project) { create(:project) }

      it 'returns the total repository and lfs size' do
        allow(project.statistics).to receive(:total_repository_size).and_return(80)

        expect(checker.current_size).to eq(80)
      end
    end

    describe '#limit' do
      it 'returns the value set in the namespace when available' do
        allow(project.namespace).to receive(:actual_size_limit).and_return(100)

        expect(checker.limit).to eq(100)
      end

      it 'returns the value set locally when available' do
        project.repository_size_limit = 200

        expect(checker.limit).to eq(200)
      end
    end

    describe '#enabled?' do
      it 'returns true when not equal to zero' do
        project.repository_size_limit = 1

        expect(checker.enabled?).to be_truthy
      end

      it 'returns false when equals to zero' do
        project.repository_size_limit = 0

        expect(checker.enabled?).to be_falsey
      end

      context 'when repository_size_limit is configured' do
        before do
          project.repository_size_limit = 1
        end

        context 'when license feature enabled' do
          before do
            stub_licensed_features(repository_size_limit: true)
          end

          it 'is enabled' do
            expect(checker.enabled?).to be_truthy
          end
        end

        context 'when license feature disabled' do
          before do
            stub_licensed_features(repository_size_limit: false)
          end

          it 'is disabled' do
            expect(checker.enabled?).to be_falsey
          end
        end
      end
    end
  end

  describe '#repository_size_excess' do
    subject { project.repository_size_excess }

    let_it_be(:statistics) { create(:project_statistics) }
    let_it_be(:project) { statistics.project }

    where(:total_repository_size, :size_limit, :result) do
      50 | nil | 0
      50 | 0   | 0
      50 | 60  | 0
      50 | 50  | 0
      50 | 10  | 40
    end

    with_them do
      before do
        allow(project).to receive(:actual_size_limit).and_return(size_limit)
        allow(statistics).to receive(:total_repository_size).and_return(total_repository_size)
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '#repository_size_limit column' do
    it 'support values up to 8 exabytes' do
      project = create(:project)
      project.update_column(:repository_size_limit, 8.exabytes - 1)

      project.reload

      expect(project.repository_size_limit).to eql(8.exabytes - 1)
    end
  end

  describe 'handling import URL' do
    context 'when project is a mirror' do
      it 'returns the full URL' do
        project = create(:project, :mirror, import_url: 'http://user:pass@test.com')

        project.import_state.finish

        expect(project.reload.import_url).to eq('http://user:pass@test.com')
      end
    end

    context 'project is inside a fork network' do
      subject { project }

      let(:project) { create(:project, fork_network: fork_network) }
      let(:fork_network) { create(:fork_network) }

      before do
        stub_config_setting(host: 'gitlab.com')
      end

      context 'feature flag is disabled' do
        before do
          stub_feature_flags(block_external_fork_network_mirrors: false)
          project.import_url = "https://customgitlab.com/foo/bar.git"
        end

        it { is_expected.to be_valid }
      end

      context 'the project is the root of the fork network' do
        before do
          project.import_url = "https://customgitlab.com/foo/bar.git"
          expect(fork_network).to receive(:root_project).and_return(project)
        end

        it { is_expected.to be_valid }
      end

      context 'the URL is inside the fork network' do
        before do
          project.import_url = "https://#{Gitlab.config.gitlab.host}/#{project.fork_network.root_project.full_path}.git"
        end

        it { is_expected.to be_valid }
      end

      context 'the URL is external but the project exists' do
        it 'raises an error' do
          project.import_url = "https://customgitlab.com/#{project.fork_network.root_project.full_path}.git"
          project.validate

          expect(project.errors[:url]).to include('must be inside the fork network')
        end
      end

      context 'the URL is not inside the fork network' do
        it 'raises an error' do
          project.import_url = "https://customgitlab.com/foo/bar.git"
          project.validate

          expect(project.errors[:url]).to include('must be inside the fork network')
        end
      end
    end
  end

  describe '#add_import_job' do
    let(:import_jid) { '123' }

    context 'forked' do
      let(:forked_from_project) { create(:project, :repository) }
      let(:project) { create(:project) }

      before do
        fork_project(forked_from_project, nil, target_project: project)
      end

      context 'without mirror' do
        it 'returns nil' do
          project = create(:project)

          expect(project.add_import_job).to be nil
        end
      end

      context 'with mirror' do
        it 'schedules RepositoryUpdateMirrorWorker' do
          project = create(:project, :mirror, :repository)

          expect(RepositoryUpdateMirrorWorker).to receive(:perform_async).with(project.id).and_return(import_jid)
          expect(project.add_import_job).to eq(import_jid)
        end
      end
    end
  end

  describe '.where_full_path_in' do
    context 'without any paths' do
      it 'returns an empty relation' do
        expect(described_class.where_full_path_in([])).to eq([])
      end
    end

    context 'without any valid paths' do
      it 'returns an empty relation' do
        expect(described_class.where_full_path_in(%w[foo])).to eq([])
      end
    end

    context 'with valid paths' do
      let!(:project1) { create(:project) }
      let!(:project2) { create(:project) }

      it 'returns the projects matching the paths' do
        projects = described_class.where_full_path_in([project1.full_path,
                                                       project2.full_path])

        expect(projects).to contain_exactly(project1, project2)
      end

      it 'returns projects regardless of the casing of paths' do
        projects = described_class.where_full_path_in([project1.full_path.upcase,
                                                       project2.full_path.upcase])

        expect(projects).to contain_exactly(project1, project2)
      end
    end
  end

  describe '#approver_group_ids=' do
    let(:project) { create(:project) }

    it 'create approver_groups' do
      group = create :group
      group1 = create :group

      project = create :project

      project.approver_group_ids = "#{group.id}, #{group1.id}"
      project.save!

      expect(project.approver_groups.map(&:group)).to match_array([group, group1])
    end
  end

  describe '#create_import_state' do
    it 'is called after save' do
      project = create(:project)

      expect(project).to receive(:create_import_state)

      project.update(mirror: true, mirror_user: project.owner, import_url: 'http://foo.com')
    end
  end

  describe '#allowed_to_share_with_group?' do
    context 'for group related project' do
      subject(:project) { build_stubbed(:project, namespace: group, group: group) }

      let(:group) { build_stubbed :group }

      context 'with lock_memberships_to_ldap application setting enabled' do
        before do
          stub_application_setting(lock_memberships_to_ldap: true)
        end

        it { is_expected.not_to be_allowed_to_share_with_group }
      end
    end

    context 'personal project' do
      subject(:project) { build_stubbed(:project, namespace: namespace) }

      let(:namespace) { build_stubbed :namespace }

      context 'with lock_memberships_to_ldap application setting enabled' do
        before do
          stub_application_setting(lock_memberships_to_ldap: true)
        end

        it { is_expected.to be_allowed_to_share_with_group }
      end
    end
  end

  # Despite stubbing the current node as the primary or secondary, the
  # behaviour for EE::Project#lfs_http_url_to_repo() is to call
  # Project#lfs_http_url_to_repo() which does not have a Geo context.
  def stub_default_url_options(host)
    allow(Rails.application.routes)
      .to receive(:default_url_options)
      .and_return(host: host)
  end

  describe '#ancestor_marked_for_deletion' do
    context 'delayed deletion feature is not available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: false)
      end

      context 'the parent namespace has been marked for deletion' do
        let(:parent_group) do
          create(:group_with_deletion_schedule, marked_for_deletion_on: 1.day.ago)
        end

        let(:project) { create(:project, namespace: parent_group) }

        it 'returns nil' do
          expect(project.ancestor_marked_for_deletion).to be_nil
        end
      end
    end

    context 'delayed deletion feature is available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
      end

      context 'the parent namespace has been marked for deletion' do
        let(:parent_group) do
          create(:group_with_deletion_schedule, marked_for_deletion_on: 1.day.ago)
        end

        let(:project) { create(:project, namespace: parent_group) }

        it 'returns the parent namespace' do
          expect(project.ancestor_marked_for_deletion).to eq(parent_group)
        end
      end

      context "project or its parent group has not been marked for deletion" do
        let(:parent_group) { create(:group) }
        let(:project) { create(:project, namespace: parent_group) }

        it 'returns nil' do
          expect(project.ancestor_marked_for_deletion).to be_nil
        end
      end

      context 'ordering' do
        let(:group_a) { create(:group_with_deletion_schedule, marked_for_deletion_on: 1.day.ago) }
        let(:subgroup_a) { create(:group_with_deletion_schedule, marked_for_deletion_on: 1.day.ago, parent: group_a) }
        let(:project) { create(:project, namespace: subgroup_a) }

        it 'returns the first group that is marked for deletion, up its ancestry chain' do
          expect(project.ancestor_marked_for_deletion).to eq(subgroup_a)
        end
      end
    end
  end

  describe '#adjourned_deletion?' do
    subject { project.adjourned_deletion? }

    where(:licensed?, :feature_enabled_on_group?, :adjourned_period, :result) do
      true    | true  | 0 | false
      true    | true  | 1 | true
      true    | false | 0 | false
      true    | false | 1 | false
      false   | true  | 0 | false
      false   | true  | 1 | false
      false   | false | 0 | false
      false   | false | 1 | false
    end

    with_them do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, group: group) }

      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: licensed?)
        stub_application_setting(deletion_adjourned_period: adjourned_period)
        allow(group.namespace_settings).to receive(:delayed_project_removal?).and_return(feature_enabled_on_group?)
      end

      it { is_expected.to be result }
    end

    context 'when project belongs to user namespace' do
      let_it_be(:user) { create(:user) }
      let_it_be(:user_project) { create(:project, namespace: user.namespace) }

      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
        stub_application_setting(deletion_adjourned_period: 7)
      end

      it 'deletes immediately' do
        expect(user_project.adjourned_deletion?).to be nil
      end
    end
  end

  describe 'calculate template repositories' do
    let(:group1) { create(:group) }
    let(:group2) { create(:group) }
    let(:group2_sub1) { create(:group, parent: group2) }
    let(:group2_sub2) { create(:group, parent: group2) }

    before do
      stub_ee_application_setting(custom_project_templates_group_id: group2.id)
      group2.update(custom_project_templates_group_id: group2_sub2.id)
      create(:project, group: group1)

      create_list(:project, 2, group: group2)
      create_list(:project, 3, group: group2_sub1)
      create_list(:project, 4, group: group2_sub2)
    end

    it 'counts instance level templates' do
      expect(described_class.with_repos_templates.count).to eq(2)
    end

    it 'counts group level templates' do
      expect(described_class.with_groups_level_repos_templates.count).to eq(4)
    end
  end

  describe '#license_compliance' do
    it { expect(subject.license_compliance).to be_instance_of(::SCA::LicenseCompliance) }
  end

  describe '#template_source?' do
    let_it_be(:group) { create(:group, :private) }
    let_it_be(:subgroup) { create(:group, :private, parent: group) }
    let_it_be(:project_template) { create(:project, group: subgroup) }

    context 'when project is not template source' do
      it 'returns false' do
        expect(project.template_source?).to be_falsey
      end
    end

    context 'instance-level custom project templates' do
      before do
        stub_ee_application_setting(custom_project_templates_group_id: subgroup.id)
      end

      it 'returns true' do
        expect(project_template.template_source?).to be_truthy
      end
    end

    context 'group-level custom project templates' do
      before do
        group.update(custom_project_templates_group_id: subgroup.id)
      end

      it 'returns true' do
        expect(project_template.template_source?).to be_truthy
      end
    end
  end

  describe '#remove_import_data' do
    let(:import_data) { ProjectImportData.new(data: { 'test' => 'some data' }) }

    context 'when mirror' do
      let(:user) { create(:user) }
      let!(:project) { create(:project, mirror: true, import_url: 'http://some_url.com', mirror_user_id: user.id, import_data: import_data) }

      it 'does not remove import data' do
        expect(project.mirror?).to be true
        expect(project.jira_import?).to be false
        expect { project.remove_import_data }.not_to change { ProjectImportData.count }
      end
    end
  end

  describe '#add_template_export_job' do
    it 'starts project template export job' do
      user = create(:user)
      project = build(:project)

      expect(ProjectTemplateExportWorker).to receive(:perform_async).with(user.id, project.id, nil, {})

      project.add_template_export_job(current_user: user)
    end
  end

  describe '#prevent_merge_without_jira_issue?' do
    subject { project.prevent_merge_without_jira_issue? }

    where(:feature_available, :prevent_merge, :result) do
      true  | true  | true
      true  | false | false
      false | true  | false
      false | false | false
    end

    with_them do
      before do
        allow(project).to receive(:jira_issue_association_required_to_merge_enabled?).and_return(feature_available)
        project.create_project_setting(prevent_merge_without_jira_issue: prevent_merge)
      end

      it { is_expected.to be result }
    end
  end

  context 'indexing updates in Elasticsearch', :elastic do
    before do
      stub_ee_application_setting(elasticsearch_indexing: true)
    end

    context 'on update' do
      let(:project) { create(:project, :public) }
      let!(:issue) { create(:issue, project: project) }
      let!(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

      context 'when updating the visibility_level' do
        it 'triggers ElasticAssociationIndexerWorker to update issues, merge_requests and notes' do
          expect(ElasticAssociationIndexerWorker).to receive(:perform_async).with('Project', project.id, %w[issues merge_requests notes])

          project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        end

        it 'ensures all visibility_level updates are correctly applied in issue searches', :sidekiq_inline do
          ensure_elasticsearch_index!
          results = Issue.elastic_search('*', options: { public_and_internal_projects: true })
          expect(results.count).to eq(1)

          project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
          ensure_elasticsearch_index!

          results = Issue.elastic_search('*', options: { public_and_internal_projects: true })
          expect(results.count).to eq(0)
        end

        it 'ensures all visibility_level updates are correctly applied in merge_request searches', :sidekiq_inline do
          ensure_elasticsearch_index!
          results = MergeRequest.elastic_search('*', options: { public_and_internal_projects: true })
          expect(results.count).to eq(1)

          project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
          ensure_elasticsearch_index!

          results = MergeRequest.elastic_search('*', options: { public_and_internal_projects: true })
          expect(results.count).to eq(0)
        end
      end

      context 'when changing the title' do
        it 'does not trigger ElasticAssociationIndexerWorker to update issues' do
          expect(ElasticAssociationIndexerWorker).not_to receive(:perform_async)

          project.update!(title: 'The new title')
        end
      end
    end
  end

  describe '#available_shared_runners' do
    let_it_be(:runner) { create(:ci_runner, :instance) }

    let(:project) { build_stubbed(:project, shared_runners_enabled: true) }

    subject { project.available_shared_runners }

    before do
      allow(project).to receive(:ci_minutes_quota)
        .and_return(double('quota', minutes_used_up?: minutes_used_up))
    end

    context 'when CI minutes are available for project' do
      let(:minutes_used_up) { false }

      it 'returns a list of shared runners' do
        is_expected.to eq([runner])
      end
    end

    context 'when out of CI minutes for project' do
      let(:minutes_used_up) { true }

      it 'returns a empty list' do
        is_expected.to be_empty
      end
    end
  end

  describe '#all_available_runners' do
    let_it_be_with_refind(:project) do
      create(:project, group: create(:group), shared_runners_enabled: true)
    end

    let_it_be(:instance_runner) { create(:ci_runner, :instance) }
    let_it_be(:group_runner) { create(:ci_runner, :group, groups: [project.group]) }
    let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project]) }

    subject { project.all_available_runners }

    before do
      allow(project).to receive(:ci_minutes_quota)
        .and_return(double('quota', minutes_used_up?: minutes_used_up))
    end

    context 'when CI minutes are available for project' do
      let(:minutes_used_up) { false }

      it 'returns a list with all runners' do
        is_expected.to match_array([instance_runner, group_runner, project_runner])
      end
    end

    context 'when out of CI minutes for project' do
      let(:minutes_used_up) { true }

      it 'returns a list with specific runners' do
        is_expected.to match_array([group_runner, project_runner])
      end
    end
  end

  describe '#force_cost_factor?' do
    context 'on gitlab.com' do
      context 'when public' do
        context 'when ci_minutes_public_project_cost_factor is enabled' do
          context 'when in a namespace created after 17 July, 2021' do
            it 'returns true' do
              stub_feature_flags(ci_minutes_public_project_cost_factor: true)
              allow(::Gitlab).to receive(:com?).and_return(true)
              namespace = build(:group, created_at: Date.new(2021, 7, 17))
              project = build(:project, :public, namespace: namespace)

              expect(project.force_cost_factor?).to be_truthy
            end
          end

          context 'when in a namespace created before 17 July, 2021' do
            it 'returns false' do
              stub_feature_flags(ci_minutes_public_project_cost_factor: true)
              allow(::Gitlab).to receive(:com?).and_return(true)
              namespace = build(:group, created_at: Date.new(2021, 7, 16))
              project = build(:project, :public, namespace: namespace)

              expect(project.force_cost_factor?).to be_falsy
            end
          end
        end

        context 'when ci_minutes_public_project_cost_factor is disabled' do
          it 'returns false' do
            stub_feature_flags(ci_minutes_public_project_cost_factor: false)
            allow(::Gitlab).to receive(:com?).and_return(true)
            namespace = build(:group, created_at: Date.new(2021, 7, 16))
            project = build(:project, :public, namespace: namespace)

            expect(project.force_cost_factor?).to be_falsy
          end
        end
      end

      context 'when not public' do
        it 'returns false' do
          stub_feature_flags(ci_minutes_public_project_cost_factor: true)
          allow(::Gitlab).to receive(:com?).and_return(true)
          namespace = build(:group, created_at: Date.new(2021, 7, 17))
          project = build(:project, :private, namespace: namespace)

          expect(project.force_cost_factor?).to be_falsy
        end
      end
    end

    context 'when not on gitlab.com' do
      it 'returns false' do
        stub_feature_flags(ci_minutes_public_project_cost_factor: true)
        allow(::Gitlab).to receive(:com?).and_return(false)
        namespace = build(:group, created_at: Date.new(2021, 7, 17))
        project = build(:project, :public, namespace: namespace)

        expect(project.force_cost_factor?).to be_falsy
      end
    end
  end
end
