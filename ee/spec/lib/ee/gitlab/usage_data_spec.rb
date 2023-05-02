# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageData, feature_category: :service_ping do
  include UsageDataHelpers

  before do
    stub_usage_data_connections
    stub_database_flavor_check
    clear_memoized_values(described_class::EE_MEMOIZED_VALUES + described_class::CE_MEMOIZED_VALUES)
  end

  describe '.data' do
    let_it_be(:group) { create(:group) }

    # rubocop:disable RSpec/FactoryBot/CreateList
    # using Array.new to create a different creator User for each of the projects
    let_it_be(:projects) do
      Array.new(3) do
        create(:project, :repository, group: group, creator: create(:user, group_view: :security_dashboard))
      end
    end
    # rubocop:enable RSpec/FactoryBot/CreateList

    let_it_be(:board) { create(:board, project: projects[0]) }

    let(:count_data) { subject[:counts] }

    before_all do
      projects.last.creator.block # to get at least one non-active User

      pipeline = create(:ci_pipeline, project: projects[0])
      create(:ci_build, name: 'container_scanning', pipeline: pipeline)
      create(:ci_build, name: 'dast', pipeline: pipeline)
      create(:ci_build, name: 'dependency_scanning', pipeline: pipeline)
      create(:ci_build, name: 'license_management', pipeline: pipeline)
      create(:ee_ci_build, name: 'license_scanning', pipeline: pipeline)
      create(:ci_build, name: 'sast', pipeline: pipeline)
      create(:ci_build, name: 'secret_detection', pipeline: pipeline)
      create(:ci_build, name: 'coverage_fuzzing', pipeline: pipeline)
      create(:ci_build, name: 'apifuzzer_fuzz', pipeline: pipeline)
      create(:ci_build, name: 'apifuzzer_fuzz_dnd', pipeline: pipeline)
      create(:ci_pipeline, source: :ondemand_dast_scan, project: projects[0])

      create(:prometheus_alert, project: projects[0])
      create(:prometheus_alert, project: projects[0])
      create(:prometheus_alert, project: projects[1])

      create(:jira_integration, project: projects[0], issues_enabled: true, project_key: 'GL')

      create(:issue, project: projects[1])
      create(:issue, health_status: :on_track, project: projects[1])
      create(:issue, health_status: :at_risk, project: projects[1])

      # for group_view testing
      create(:user) # user with group_view = NULL (should be counted as having default value 'details')
      create(:user, group_view: :details)

      # Status Page
      create(:status_page_setting, project: projects[0], enabled: true)
      create(:status_page_setting, project: projects[1], enabled: false)
      # 1 published issue on 1 projects with status page enabled
      issue_1 = create(:issue, project: projects[0])
      issue_2 = create(:issue, :published, project: projects[0])
      create(:issue, :published, project: projects[1])

      create(:epic_issue, issue: issue_2)
      create(:epic_issue, issue: issue_1)
    end

    subject { described_class.data }

    it 'gathers usage data', :fips_mode do
      expect(subject.keys).to include(
        *%i(
          historical_max_users
          license_add_ons
          license_plan
          license_expires_at
          license_starts_at
          license_user_count
          license_trial
          license_subscription_id
          licensee
          license_md5
          license_sha256
          license_id
          elasticsearch_enabled
          geo_enabled
          license_trial_ends_on
          license_billable_users
        ))

      expect(subject[:license_md5]).to eq(nil)
    end

    context 'when not in FIPS mode', fips_mode: false do
      it 'includes MD5' do
        expect(subject.keys).to include(:license_md5)
        expect(subject[:license_md5]).to be_present
      end
    end

    it 'gathers usage counts', :aggregate_failures do
      expect(count_data[:projects]).to eq(3)

      expect(count_data.keys).to include(
        *%i(
          confidential_epics
          epics
          epic_issues
          geo_nodes
          geo_event_log_max_id
          issues_with_health_status
          ldap_group_links
          ldap_keys
          ldap_users
          operations_dashboard_default_dashboard
          operations_dashboard_users_with_projects_added
          projects_jira_issuelist_active
          projects_mirrored_with_pipelines_enabled
          projects_reporting_ci_cd_back_to_github
          status_page_issues
          status_page_projects
          user_preferences_group_overview_details
          template_repositories
        ))

      expect(count_data[:status_page_projects]).to eq(1)
      expect(count_data[:status_page_issues]).to eq(1)
      expect(count_data[:issues_with_health_status]).to eq(2)
      expect(count_data[:projects_jira_issuelist_active]).to eq(1)
      expect(count_data[:epic_issues]).to eq(2)
    end

    it 'gathers security products usage data' do
      expect(count_data[:dast_on_demand_pipelines]).to eq(1)
    end

    it 'gathers group overview preferences usage data', :aggregate_failures do
      expect(subject[:counts][:user_preferences_group_overview_details]).to eq(User.active.count - 2) # we have exactly 2 active users with security dashboard set
    end

    it 'includes a recording_ee_finished_at timestamp' do
      expect(subject[:recording_ee_finished_at]).to be_a(Time)
    end
  end

  describe '.features_usage_data_ee' do
    subject { described_class.features_usage_data_ee }

    it 'gathers feature usage data of EE' do
      expect(subject[:elasticsearch_enabled]).to eq(Gitlab::CurrentSettings.elasticsearch_search?)
      expect(subject[:geo_enabled]).to eq(Gitlab::Geo.enabled?)
      expect(subject[:license_trial_ends_on]).to eq(License.trial_ends_on)
    end
  end

  describe '.license_usage_data' do
    subject { described_class.license_usage_data }

    it 'gathers license data', :fips_mode do
      license = ::License.current

      expect(subject[:license_id]).to eq(license.license_id)
      expect(subject[:license_user_count]).to eq(license.restricted_user_count)
      expect(subject[:license_starts_at]).to eq(license.starts_at)
      expect(subject[:license_expires_at]).to eq(license.expires_at)
      expect(subject[:license_add_ons]).to eq(license.add_ons)
      expect(subject[:license_trial]).to eq(license.trial?)
      expect(subject[:license_subscription_id]).to eq(license.subscription_id)
      expect(subject[:license_billable_users]).to eq(license.daily_billable_users_count)
      expect(subject[:licensee]).to eq(license.licensee)
      expect(subject[:license_md5]).to eq(nil)
      expect(subject[:license_sha256]).to eq(Digest::SHA256.hexdigest(license.data))
      expect(subject[:historical_max_users]).to eq(license.historical_max)
    end

    context 'when not in FIPS mode', fips_mode: false do
      it 'includes MD5' do
        license = ::License.current

        expect(subject[:license_md5]).to eq(Digest::MD5.hexdigest(license.data))
      end
    end
  end

  describe '.components_usage_data' do
    subject { described_class.components_usage_data }

    it 'gathers components usage data' do
      stub_ee_application_setting(elasticsearch_indexing: true)

      expect(subject[:advanced_search]).to eq(Gitlab::Elastic::Helper.default.server_info)
    end
  end

  describe '.requirements_counts' do
    subject { described_class.requirements_counts }

    let_it_be(:requirement1) { create(:work_item, :requirement) }
    let_it_be(:requirement2) { create(:work_item, :requirement) }
    let_it_be(:requirement3) { create(:work_item, :requirement) }
    let_it_be(:test_report1) { create(:test_report, requirement_issue: requirement1) }
    let_it_be(:test_report2) { create(:test_report, requirement_issue: requirement2, build: nil) }
    let_it_be(:test_report3) { create(:test_report, requirement_issue: requirement1) }

    context 'when requirements are disabled' do
      it 'returns empty hash' do
        stub_licensed_features(requirements: false)

        expect(subject).to eq({})
      end
    end

    context 'when requirements are enabled' do
      it 'returns created requirements count' do
        stub_licensed_features(requirements: true)

        expect(subject).to eq({
          requirements_created: 3,
          requirement_test_reports_manual: 1,
          requirement_test_reports_ci: 2,
          requirements_with_test_report: 2
        })
      end
    end
  end

  describe 'merge requests merged using approval rules' do
    before do
      create(:approval_merge_request_rule, merge_request: create(:merge_request, :merged))
      create(:approval_merge_request_rule, merge_request: create(:merge_request))
    end

    it 'counts the approval rules for merged merge requests' do
      expect(described_class.system_usage_data[:counts][:merged_merge_requests_using_approval_rules]).to eq(1)
    end
  end

  describe '.operations_dashboard_usage' do
    subject { described_class.operations_dashboard_usage }

    before_all do
      blocked_user = create(:user, :blocked, dashboard: 'operations')
      user_with_ops_dashboard = create(:user, dashboard: 'operations')

      create(:users_ops_dashboard_project, user: blocked_user)
      create(:users_ops_dashboard_project, user: user_with_ops_dashboard)
      create(:users_ops_dashboard_project, user: user_with_ops_dashboard)
      create(:users_ops_dashboard_project)
    end

    it 'gathers data on operations dashboard' do
      expect(subject.keys).to include(*%i(
                                        operations_dashboard_default_dashboard
                                        operations_dashboard_users_with_projects_added
                                      ))
    end

    it 'bases counts on active users', :aggregate_failures do
      expect(subject[:operations_dashboard_default_dashboard]).to eq(1)
      expect(subject[:operations_dashboard_users_with_projects_added]).to eq(2)
    end
  end

  describe 'usage_activity_by_stage_configure' do
    it 'includes accurate usage_activity_by_stage data' do
      for_defined_days_back do
        user = create(:user)
        project = create(:project, creator: user)
        create(:integrations_slack, project: project)
        create(:slack_slash_commands_integration, project: project)
        create(:prometheus_integration, project: project)
      end

      expect(described_class.usage_activity_by_stage_configure({})).to include(
        projects_slack_notifications_active: 2,
        projects_slack_slash_active: 2
      )
      expect(described_class.usage_activity_by_stage_configure(described_class.monthly_time_range_db_params)).to include(
        projects_slack_notifications_active: 1,
        projects_slack_slash_active: 1
      )
    end
  end

  describe 'usage_activity_by_stage_create' do
    it 'includes accurate usage_activity_by_stage data', :aggregate_failures do
      for_defined_days_back do
        user = create(:user)
        project = create(:project, :repository_private, :github_imported,
                          :test_repo, creator: user)
        merge_request = create(:merge_request, source_project: project)
        overridden_merge_request = create(:merge_request, source_project: project, target_branch: "override")
        project_rule = create(:approval_project_rule, project: project)
        overridden_project_rule = create(:approval_project_rule, project: project, approvals_required: 1)
        merge_rule = create(:approval_merge_request_rule, merge_request: merge_request)
        overridden_mr_rule = create(:approval_merge_request_rule, merge_request: overridden_merge_request, approvals_required: 5)
        create(:approval_merge_request_rule_source, approval_merge_request_rule: merge_rule, approval_project_rule: project_rule)
        create(:approval_merge_request_rule_source, approval_merge_request_rule: overridden_mr_rule, approval_project_rule: overridden_project_rule)
        create(:project, creator: user)
        create(:project, creator: user, disable_overriding_approvers_per_merge_request: true)
        create(:project, creator: user, disable_overriding_approvers_per_merge_request: false)
        create(:approval_project_rule, project: project, users: create_list(:user, 2), approvals_required: 1)
        create(:approval_project_rule, project: project, users: [create(:user)], approvals_required: 1)
        protected_branch = create(:protected_branch, project: project)
        create(:approval_project_rule, protected_branches: [protected_branch], users: [create(:user)], approvals_required: 2, project: project)
        create(:code_owner_rule, merge_request: merge_request, approvals_required: 3)
        create(:code_owner_rule, merge_request: merge_request, approvals_required: 7, section: 'new_section')
        create(:approval_merge_request_rule, merge_request: merge_request)
        create_list(:code_owner_rule, 3, approvals_required: 2)
        create_list(:code_owner_rule, 2)

        create(:lfs_file_lock, project: project, path: 'a.txt')
        create(:lfs_file_lock, project: project, path: 'b.txt')
        create(:lfs_file_lock, user: user, project: project, path: 'c.txt')
        create(:lfs_file_lock, user: user, project: project, path: 'd.txt')

        create(:path_lock, project: project, path: '1.txt')
        create(:path_lock, project: project, path: '2.txt')
        create(:path_lock, project: project, path: '3.txt')
        create(:path_lock, user: user, project: project, path: '4.txt')
        create(:path_lock, user: user, project: project, path: '5.txt')
        create(:path_lock, user: user, project: project, path: '6.txt')

        create_list(:lfs_file_lock, 3)
        create_list(:path_lock, 4)
      end

      expect(described_class.usage_activity_by_stage_create({})).to include(
        approval_project_rules: 10,
        approval_project_rules_with_target_branch: 2,
        approval_project_rules_with_more_approvers_than_required: 2,
        approval_project_rules_with_less_approvers_than_required: 2,
        approval_project_rules_with_exact_required_approvers: 2,
        projects_enforcing_code_owner_approval: 0,
        projects_with_sectional_code_owner_rules: 2,
        merge_requests_with_added_rules: 12,
        merge_requests_with_optional_codeowners: 4,
        merge_requests_with_required_codeowners: 8,
        merge_requests_with_overridden_project_rules: 4,
        projects_imported_from_github: 2,
        projects_with_repositories_enabled: 26,
        protected_branches: 2,
        users_using_lfs_locks: 12,
        users_using_path_locks: 16,
        total_number_of_path_locks: 20,
        total_number_of_locked_files: 14
      )
      expect(described_class.usage_activity_by_stage_create(described_class.monthly_time_range_db_params)).to include(
        approval_project_rules: 10,
        approval_project_rules_with_target_branch: 2,
        approval_project_rules_with_more_approvers_than_required: 2,
        approval_project_rules_with_less_approvers_than_required: 2,
        approval_project_rules_with_exact_required_approvers: 2,
        projects_enforcing_code_owner_approval: 0,
        projects_with_sectional_code_owner_rules: 1,
        merge_requests_with_added_rules: 6,
        merge_requests_with_optional_codeowners: 2,
        merge_requests_with_required_codeowners: 4,
        projects_imported_from_github: 1,
        projects_with_repositories_enabled: 13,
        protected_branches: 1,
        users_using_lfs_locks: 6,
        users_using_path_locks: 8,
        total_number_of_path_locks: 10,
        total_number_of_locked_files: 7
      )
    end
  end

  describe 'usage_data_by_stage_enablement' do
    it 'returns empty hash if geo is not enabled' do
      expect(described_class.usage_activity_by_stage_enablement({})).to eq({})
    end

    context 'geo enabled' do
      before do
        create_list(:geo_node, 2, :secondary).each do |node|
          for_defined_days_back do
            create(:oauth_access_grant, application: node.oauth_application)
          end
        end

        create(:geo_node, :secondary, enabled: false)
        create(:geo_node, :primary)

        GeoNode.all.each do |node|
          create(:geo_node_status, geo_node: node)
        end
      end

      subject do
        described_class.usage_activity_by_stage_enablement(described_class.monthly_time_range_db_params)
      end

      it 'excludes data outside of the date range' do
        expect(subject).to include(geo_secondary_web_oauth_users: 2)
      end

      context 'node status fields' do
        it 'only includes active secondary nodes' do
          expect(subject[:geo_node_usage].size).to eq(2)
        end

        it 'includes all resource status fields' do
          expect(subject[:geo_node_usage].first.keys).to eq(GeoNodeStatus::RESOURCE_STATUS_FIELDS)
        end
      end
    end
  end

  describe 'usage_activity_by_stage_manage' do
    it 'includes accurate usage_activity_by_stage data' do
      stub_config(
        ldap:
          { enabled: true, servers: ldap_server_config }
      )

      for_defined_days_back do
        user = create(:user)
        create(:key, type: 'LDAPKey', user: user)
        create(:group_member, ldap: true, user: user)
        create(:cycle_analytics_stage)
        create(:compliance_framework_project_setting)
        create(:compliance_framework)
        create(:compliance_framework, :with_pipeline)
      end

      expect(described_class.usage_activity_by_stage_manage({})).to include(
        ldap_keys: 2,
        ldap_users: 2,
        value_stream_management_customized_group_stages: 2,
        projects_with_compliance_framework: 2,
        custom_compliance_frameworks: 6,
        compliance_frameworks_with_pipeline: 2,
        ldap_servers: 2,
        ldap_group_sync_enabled: true,
        ldap_admin_sync_enabled: true,
        group_saml_enabled: true
      )
      expect(described_class.usage_activity_by_stage_manage(described_class.monthly_time_range_db_params)).to include(
        ldap_keys: 1,
        ldap_users: 1,
        value_stream_management_customized_group_stages: 2,
        projects_with_compliance_framework: 2,
        custom_compliance_frameworks: 3,
        compliance_frameworks_with_pipeline: 1,
        ldap_servers: 2,
        ldap_group_sync_enabled: true,
        ldap_admin_sync_enabled: true,
        group_saml_enabled: true
      )
    end

    def ldap_server_config
      {
        'main' =>
        {
          'provider_name' => 'ldapmain',
          'group_base'    => 'ou=groups',
          'admin_group'   => 'my_group'
        },
        'secondary' =>
        {
          'provider_name' => 'ldapsecondary',
          'group_base'    => nil,
          'admin_group'   => nil
        }
      }
    end
  end

  describe 'usage_activity_by_stage_monitor' do
    it 'includes accurate usage_activity_by_stage data' do
      for_defined_days_back do
        user    = create(:user, dashboard: 'operations')
        project = create(:project, creator: user)
        create(:users_ops_dashboard_project, user: user)
        create(:prometheus_integration, project: project)
        create(:project_incident_management_setting, :sla_enabled, project: project)
      end

      expect(described_class.usage_activity_by_stage_monitor({})).to include(
        operations_dashboard_users_with_projects_added: 2,
        projects_incident_sla_enabled: 2
      )
      expect(described_class.usage_activity_by_stage_monitor(described_class.monthly_time_range_db_params)).to include(
        operations_dashboard_users_with_projects_added: 1
      )
    end
  end

  describe 'usage_activity_by_stage_plan' do
    it 'includes accurate usage_activity_by_stage data' do
      stub_licensed_features(board_assignee_lists: true, board_milestone_lists: true)

      for_defined_days_back do
        user = create(:user)
        project = create(:project, creator: user)
        board = create(:board, project: project)
        create(:user_list, board: board, user: user)
        create(:milestone_list, board: board, milestone: create(:milestone, project: project), user: user)
        create(:list, board: board, label: create(:label, project: project), user: user)
        create(:epic, author: user)
      end

      expect(described_class.usage_activity_by_stage_plan({})).to include(
        assignee_lists: 2,
        epics: 2,
        label_lists: 2,
        milestone_lists: 2
      )
      expect(described_class.usage_activity_by_stage_plan(described_class.monthly_time_range_db_params)).to include(
        assignee_lists: 1,
        epics: 1,
        label_lists: 1,
        milestone_lists: 1
      )
    end
  end

  describe 'usage_activity_by_stage_release' do
    before do
      stub_licensed_features(group_milestone_project_releases: true)
      group_milestone = create(:milestone, :on_group)
      project = create(:project, group: group_milestone.group)

      for_defined_days_back do
        create(:project, :mirror, mirror_trigger_builds: true)

        create(:release, created_at: 3.days.ago, project: project, milestones: [group_milestone])
      end
    end

    it 'includes accurate usage_activity_by_stage data' do
      expect(described_class.usage_activity_by_stage_release({})).to include(projects_mirrored_with_pipelines_enabled: 2)
      expect(described_class.usage_activity_by_stage_release(described_class.monthly_time_range_db_params)).to include(projects_mirrored_with_pipelines_enabled: 1)
      expect(described_class.usage_activity_by_stage_release({})).to include(releases_with_group_milestones: 2)
      expect(described_class.usage_activity_by_stage_release(described_class.monthly_time_range_db_params)).to include(releases_with_group_milestones: 1)
    end
  end

  describe 'usage_activity_by_stage_secure' do
    let_it_be(:error_rate) { Gitlab::Database::PostgresHll::BatchDistinctCounter::ERROR_RATE }
    let_it_be(:days_ago_within_monthly_time_period) { 3.days.ago }
    let_it_be(:user) { create(:user, group_view: :security_dashboard, created_at: days_ago_within_monthly_time_period) }
    let_it_be(:user2) { create(:user, group_view: :security_dashboard, created_at: days_ago_within_monthly_time_period) }
    let_it_be(:user3) { create(:user, group_view: :security_dashboard, created_at: days_ago_within_monthly_time_period) }

    before do
      for_defined_days_back do
        create(:ci_build, name: 'apifuzzer_fuzz', user: user)
        create(:ci_build, name: 'apifuzzer_fuzz_dnd', user: user)
        create(:ci_build, name: 'container_scanning', user: user)
        create(:ci_build, name: 'coverage_fuzzing', user: user)
        create(:ci_build, name: 'dast', user: user)
        create(:ci_build, name: 'dependency_scanning', user: user)
        create(:ci_build, name: 'license_management', user: user)
        create(:ci_build, name: 'sast', user: user)
        create(:ci_build, name: 'secret_detection', user: user)
      end
    end

    it 'includes accurate usage_activity_by_stage data' do
      expect(described_class.usage_activity_by_stage_secure(described_class.monthly_time_range_db_params)).to include(
        sast_pipeline: be_within(error_rate).percent_of(0),
        sast_scans: 0,
        dependency_scanning_pipeline: be_within(error_rate).percent_of(0),
        dependency_scanning_scans: 0,
        container_scanning_pipeline: be_within(error_rate).percent_of(0),
        container_scanning_scans: 0,
        dast_pipeline: be_within(error_rate).percent_of(0),
        dast_scans: 0,
        secret_detection_pipeline: be_within(error_rate).percent_of(0),
        secret_detection_scans: 0,
        coverage_fuzzing_pipeline: be_within(error_rate).percent_of(0),
        coverage_fuzzing_scans: 0,
        api_fuzzing_pipeline: be_within(error_rate).percent_of(0),
        api_fuzzing_scans: 0,
        user_unique_users_all_secure_scanners: 1
      )
    end

    it 'counts pipelines that have security jobs' do
      for_defined_days_back do
        ds_build = create(:ci_build, name: 'gemnasium', user: user, status: 'success')
        ds_failed_build = create(:ci_build, :failed, user: user, name: 'gemnasium')
        ds_java_build = create(:ci_build, name: 'gemnasium-maven', user: user, commit_id: ds_build.pipeline.id, status: 'success')
        secret_detection_build = create(:ci_build, name: 'secret', user: user, commit_id: ds_build.pipeline.id, status: 'success')
        cs_build = create(:ci_build, name: 'container-scanning', user: user, status: 'success')
        sast_build = create(:ci_build, name: 'sast', user: user, status: 'success', retried: true)
        create(:security_scan, build: ds_build, scan_type: 'dependency_scanning')
        create(:security_scan, build: ds_java_build, scan_type: 'dependency_scanning')
        create(:security_scan, build: secret_detection_build, scan_type: 'secret_detection')
        create(:security_scan, build: cs_build, scan_type: 'container_scanning')
        create(:security_scan, build: sast_build, scan_type: 'sast')
        create(:security_scan, build: ds_failed_build, scan_type: 'dependency_scanning')
      end

      expect(described_class.usage_activity_by_stage_secure({})).to include(
        user_unique_users_all_secure_scanners: 1,
        sast_scans: 2,
        dependency_scanning_scans: 6,
        container_scanning_scans: 2,
        dast_scans: 0,
        secret_detection_scans: 2,
        coverage_fuzzing_scans: 0
      )

      expect(described_class.usage_activity_by_stage_secure(described_class.monthly_time_range_db_params)).to include(
        sast_pipeline: be_within(error_rate).percent_of(1),
        dependency_scanning_pipeline: be_within(error_rate).percent_of(2),
        container_scanning_pipeline: be_within(error_rate).percent_of(1),
        dast_pipeline: be_within(error_rate).percent_of(0),
        secret_detection_pipeline: be_within(error_rate).percent_of(1),
        coverage_fuzzing_pipeline: be_within(error_rate).percent_of(0),
        api_fuzzing_pipeline: be_within(error_rate).percent_of(0),
        user_unique_users_all_secure_scanners: 1,
        sast_scans: 1,
        dependency_scanning_scans: 3,
        container_scanning_scans: 1,
        dast_scans: 0,
        secret_detection_scans: 1,
        coverage_fuzzing_scans: 0,
        api_fuzzing_scans: 0
      )
    end

    it 'counts unique users correctly across multiple scanners' do
      for_defined_days_back do
        create(:ci_build, name: 'sast', user: user2)
        create(:ci_build, name: 'dast', user: user2)
        create(:ci_build, name: 'dast', user: user3)
      end

      expect(described_class.usage_activity_by_stage_secure(described_class.monthly_time_range_db_params)).to include(
        sast_pipeline: be_within(error_rate).percent_of(0),
        sast_scans: 0,
        dependency_scanning_pipeline: be_within(error_rate).percent_of(0),
        dependency_scanning_scans: 0,
        container_scanning_pipeline: be_within(error_rate).percent_of(0),
        container_scanning_scans: 0,
        dast_pipeline: be_within(error_rate).percent_of(0),
        dast_scans: 0,
        secret_detection_pipeline: be_within(error_rate).percent_of(0),
        secret_detection_scans: 0,
        coverage_fuzzing_pipeline: be_within(error_rate).percent_of(0),
        coverage_fuzzing_scans: 0,
        api_fuzzing_pipeline: be_within(error_rate).percent_of(0),
        api_fuzzing_scans: 0,
        user_unique_users_all_secure_scanners: 3
      )
    end

    it 'combines license_scanning into license_management' do
      for_defined_days_back do
        create(:ci_build, name: 'license_scanning', user: user)
      end

      expect(described_class.usage_activity_by_stage_secure(described_class.monthly_time_range_db_params)).to include(
        sast_pipeline: be_within(error_rate).percent_of(0),
        sast_scans: 0,
        dependency_scanning_pipeline: be_within(error_rate).percent_of(0),
        dependency_scanning_scans: 0,
        container_scanning_pipeline: be_within(error_rate).percent_of(0),
        container_scanning_scans: 0,
        dast_pipeline: be_within(error_rate).percent_of(0),
        dast_scans: 0,
        secret_detection_pipeline: be_within(error_rate).percent_of(0),
        secret_detection_scans: 0,
        coverage_fuzzing_pipeline: be_within(error_rate).percent_of(0),
        coverage_fuzzing_scans: 0,
        api_fuzzing_pipeline: be_within(error_rate).percent_of(0),
        api_fuzzing_scans: 0,
        user_unique_users_all_secure_scanners: 1
      )
    end

    context 'when count fails' do
      subject { described_class.usage_activity_by_stage_secure(described_class.monthly_time_range_db_params) }

      before do
        allow(Gitlab::Database::BatchCount).to receive(:batch_distinct_count).and_raise(ActiveRecord::StatementInvalid)
        allow(Gitlab::Database::BatchCount).to receive(:batch_count).and_raise(ActiveRecord::StatementInvalid)
        allow(Gitlab::Database::PostgresHll::BatchDistinctCounter).to receive(:new).and_raise(ActiveRecord::StatementInvalid)
        allow(::Ci::Build).to receive(:distinct_count_by).and_raise(ActiveRecord::StatementInvalid)
        allow(Gitlab::ErrorTracking).to receive(:should_raise_for_dev?).and_return(should_raise_for_dev)
      end

      context 'with should_raise_for_dev? true' do
        let(:should_raise_for_dev) { true }

        it 'raises an error' do
          expect { subject }.to raise_error(ActiveRecord::StatementInvalid)
        end
      end

      context 'with should_raise_for_dev? false' do
        let(:should_raise_for_dev) { false }

        it 'has to resort to 0 for counting license scan' do
          for_defined_days_back do
            create(:security_scan)
          end

          expect(subject).to include(
            sast_pipeline: -1,
            sast_scans: -1,
            dependency_scanning_pipeline: -1,
            dependency_scanning_scans: -1,
            container_scanning_pipeline: -1,
            container_scanning_scans: -1,
            dast_pipeline: -1,
            dast_scans: -1,
            secret_detection_pipeline: -1,
            secret_detection_scans: -1,
            coverage_fuzzing_pipeline: -1,
            coverage_fuzzing_scans: -1,
            api_fuzzing_pipeline: -1,
            api_fuzzing_scans: -1,
            user_unique_users_all_secure_scanners: -1
          )
        end
      end
    end
  end

  describe 'usage_activity_by_stage_verify' do
    it 'includes accurate usage_activity_by_stage data' do
      for_defined_days_back do
        create(:github_integration)
      end

      expect(described_class.usage_activity_by_stage_verify({})).to include(
        projects_reporting_ci_cd_back_to_github: 2
      )
      expect(described_class.usage_activity_by_stage_verify(described_class.monthly_time_range_db_params)).to include(
        projects_reporting_ci_cd_back_to_github: 1
      )
    end
  end

  it 'clears memoized values' do
    allow(described_class).to receive(:clear_memoization)

    described_class.data

    described_class::EE_MEMOIZED_VALUES.each do |key|
      expect(described_class).to have_received(:clear_memoization).with(key)
    end
  end
end
