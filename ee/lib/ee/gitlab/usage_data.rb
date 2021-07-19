# frozen_string_literal: true

module EE
  module Gitlab
    module UsageData
      extend ActiveSupport::Concern

      EE_MEMOIZED_VALUES = %i(
        approval_merge_request_rule_minimum_id
        approval_merge_request_rule_maximum_id
        merge_request_minimum_id
        merge_request_maximum_id
      ).freeze

      SECURE_PRODUCT_TYPES = {
        container_scanning: {
          name: :container_scanning_jobs
        },
        dast: {
          name: :dast_jobs
        },
        dependency_scanning: {
          name: :dependency_scanning_jobs
        },
        license_management: {
          name: :license_management_jobs
        },
        license_scanning: {
          name: :license_scanning_jobs
        },
        sast: {
          name: :sast_jobs
        },
        secret_detection: {
          name: :secret_detection_jobs
        },
        coverage_fuzzing: {
          name: :coverage_fuzzing_jobs
        },
        apifuzzer_fuzz: {
          name: :api_fuzzing_jobs
        },
        apifuzzer_fuzz_dnd: {
          name: :api_fuzzing_dnd_jobs
        }
      }.freeze

      class_methods do
        extend ::Gitlab::Utils::Override

        override :usage_data_counters
        def usage_data_counters
          super + [
            ::Gitlab::UsageDataCounters::LicensesList,
            ::Gitlab::StatusPage::UsageDataCounters::IncidentCounter,
            ::Gitlab::UsageDataCounters::NetworkPolicyCounter
          ]
        end

        override :uncached_data
        def uncached_data
          with_finished_at(:recording_ee_finished_at) do
            super
          end
        end

        override :features_usage_data
        def features_usage_data
          super.merge(features_usage_data_ee)
        end

        def features_usage_data_ee
          {
            elasticsearch_enabled: alt_usage_data(fallback: nil) { ::Gitlab::CurrentSettings.elasticsearch_search? },
            license_trial_ends_on: alt_usage_data(fallback: nil) { License.trial_ends_on },
            geo_enabled: alt_usage_data(fallback: nil) { ::Gitlab::Geo.enabled? }
          }
        end

        override :license_usage_data
        def license_usage_data
          usage_data = super
          license = ::License.current
          usage_data[:edition] =
            if license
              license.edition
            else
              'EE Free'
            end

          if license
            usage_data[:license_md5] = license.md5
            usage_data[:license_id] = license.license_id
            # rubocop: disable UsageData/LargeTable
            usage_data[:historical_max_users] = license.historical_max
            # rubocop: enable UsageData/LargeTable
            usage_data[:licensee] = license.licensee
            usage_data[:license_user_count] = license.restricted_user_count
            usage_data[:license_billable_users] = alt_usage_data { license.daily_billable_users_count }
            usage_data[:license_starts_at] = license.starts_at
            usage_data[:license_expires_at] = license.expires_at
            usage_data[:license_plan] = license.plan
            usage_data[:license_add_ons] = license.add_ons
            usage_data[:license_trial] = license.trial?
            usage_data[:license_subscription_id] = alt_usage_data(fallback: nil) { license.subscription_id }
          end

          usage_data
        end

        def requirements_counts
          return {} unless ::License.feature_available?(:requirements)

          {
            requirements_created: count(RequirementsManagement::Requirement),
            requirement_test_reports_manual: count(RequirementsManagement::TestReport.without_build),
            requirement_test_reports_ci: count(RequirementsManagement::TestReport.with_build),
            requirements_with_test_report: distinct_count(RequirementsManagement::TestReport, :requirement_id)
          }
        end

        # rubocop:disable CodeReuse/ActiveRecord, UsageData/LargeTable
        def approval_rules_counts
          approval_project_rules_with_users =
            ApprovalProjectRule
              .regular
              .joins('INNER JOIN approval_project_rules_users ON approval_project_rules_users.approval_project_rule_id = approval_project_rules.id')
              .group(:id)

          {
            approval_project_rules: count(ApprovalProjectRule),
            approval_project_rules_with_target_branch: count(ApprovalProjectRulesProtectedBranch, :approval_project_rule_id),
            approval_project_rules_with_more_approvers_than_required: count_approval_rules_with_users(approval_project_rules_with_users.having('COUNT(approval_project_rules_users) > approvals_required')),
            approval_project_rules_with_less_approvers_than_required: count_approval_rules_with_users(approval_project_rules_with_users.having('COUNT(approval_project_rules_users) < approvals_required')),
            approval_project_rules_with_exact_required_approvers: count_approval_rules_with_users(approval_project_rules_with_users.having('COUNT(approval_project_rules_users) = approvals_required'))
          }
        end

        def count_approval_rules_with_users(relation)
          count(relation, batch_size: 10_000, start: minimum_id(ApprovalProjectRule.regular), finish: maximum_id(ApprovalProjectRule.regular)).size
        end
        # rubocop:enable CodeReuse/ActiveRecord, UsageData/LargeTable

        def security_products_usage
          results = SECURE_PRODUCT_TYPES.each_with_object({}) do |(secure_type, attribs), response|
            response[attribs[:name]] = count(::Ci::Build.where(name: secure_type)) # rubocop:disable CodeReuse/ActiveRecord
          end

          # handle license rename https://gitlab.com/gitlab-org/gitlab/issues/8911
          license_scan_count = results.delete(:license_scanning_jobs)
          results[:license_management_jobs] += license_scan_count > 0 ? license_scan_count : 0 if license_scan_count.is_a?(Integer)

          results
        end

        def on_demand_pipelines_usage
          { dast_on_demand_pipelines: count(::Ci::Pipeline.ondemand_dast_scan) }
        end

        # Note: when adding a preference, check if it's mapped to an attribute of a User model. If so, name
        # the base key part after a corresponding User model attribute, use its possible values as suffix values.
        override :user_preferences_usage
        def user_preferences_usage
          super.tap do |user_prefs_usage|
            user_prefs_usage.merge!(
              user_preferences_group_overview_details: count(::User.active.group_view_details),
              user_preferences_group_overview_security_dashboard: count(::User.active.group_view_security_dashboard)
            )
          end
        end

        def operations_dashboard_usage
          users_with_ops_dashboard_as_default = count(::User.active.with_dashboard('operations'))
          users_with_projects_added = distinct_count(UsersOpsDashboardProject.joins(:user).merge(::User.active), :user_id) # rubocop:disable CodeReuse/ActiveRecord

          {
            operations_dashboard_default_dashboard: users_with_ops_dashboard_as_default,
            operations_dashboard_users_with_projects_added: users_with_projects_added
          }
        end

        override :system_usage_data
        # Rubocop's Metrics/AbcSize metric is disabled for this method as Rubocop
        # determines this method to be too complex while there's no way to make it
        # less "complex" without introducing extra methods (which actually will
        # make things _more_ complex).
        #
        # rubocop: disable Metrics/AbcSize
        def system_usage_data
          super.tap do |usage_data|
            usage_data[:counts].merge!(
              {
                confidential_epics: count(::Epic.confidential),
                dependency_list_usages_total: redis_usage_data { ::Gitlab::UsageCounters::DependencyList.usage_totals[:total] },
                epics: count(::Epic),
                epic_issues: count(::EpicIssue),
                feature_flags: count(Operations::FeatureFlag),
                geo_nodes: count(::GeoNode),
                geo_event_log_max_id: alt_usage_data { maximum_id(Geo::EventLog) || 0 },
                ldap_group_links: count(::LdapGroupLink),
                issues_with_health_status: count(::Issue.with_health_status, start: minimum_id(::Issue), finish: maximum_id(::Issue)),
                ldap_keys: count(::LDAPKey),
                ldap_users: count(::User.ldap, 'users.id'),
                merged_merge_requests_using_approval_rules: count(::MergeRequest.merged.joins(:approval_rules), # rubocop: disable CodeReuse/ActiveRecord
                                                                  start: minimum_id(::MergeRequest),
                                                                  finish: maximum_id(::MergeRequest)),
                projects_mirrored_with_pipelines_enabled: count(::Project.mirrored_with_enabled_pipelines),
                projects_reporting_ci_cd_back_to_github: count(::Integrations::Github.active),
                status_page_projects: count(::StatusPage::ProjectSetting.enabled),
                status_page_issues: count(::Issue.on_status_page, start: minimum_id(::Issue), finish: maximum_id(::Issue)),
                template_repositories: add(count(::Project.with_repos_templates), count(::Project.with_groups_level_repos_templates))
              },
              requirements_counts,
              security_products_usage,
              on_demand_pipelines_usage,
              epics_deepest_relationship_level,
              operations_dashboard_usage)
          end
        end

        override :jira_usage
        def jira_usage
          super.merge(
            projects_jira_issuelist_active: projects_jira_issuelist_active
          )
        end

        # Omitted because no user, creator or author associated: `auto_devops_disabled`, `auto_devops_enabled`
        # Omitted because not in use anymore: `gcp_clusters`, `gcp_clusters_disabled`, `gcp_clusters_enabled`
        # rubocop:disable CodeReuse/ActiveRecord
        override :usage_activity_by_stage_configure
        def usage_activity_by_stage_configure(time_period)
          super.merge({
            projects_slack_notifications_active: distinct_count(::Project.with_slack_integration.where(time_period), :creator_id),
            projects_slack_slash_active: distinct_count(::Project.with_slack_slash_commands_integration.where(time_period), :creator_id)
          })
        end

        # Omitted because no user, creator or author associated: `lfs_objects`, `pool_repositories`, `web_hooks`
        override :usage_activity_by_stage_create
        def usage_activity_by_stage_create(time_period)
          super.merge({
            projects_enforcing_code_owner_approval: distinct_count(::Project.requiring_code_owner_approval.where(time_period), :creator_id),
            projects_with_sectional_code_owner_rules: projects_with_sectional_code_owner_rules(time_period),
            merge_requests_with_added_rules: distinct_count(::ApprovalMergeRequestRule.where(time_period).with_added_approval_rules,
                                                            :merge_request_id,
                                                            start: minimum_id(::ApprovalMergeRequestRule, :merge_request_id),
                                                            finish: maximum_id(::ApprovalMergeRequestRule, :merge_request_id)),
            merge_requests_with_optional_codeowners: distinct_count(::ApprovalMergeRequestRule.code_owner_approval_optional.where(time_period), :merge_request_id),
            merge_requests_with_overridden_project_rules: merge_requests_with_overridden_project_rules(time_period),
            merge_requests_with_required_codeowners: distinct_count(::ApprovalMergeRequestRule.code_owner_approval_required.where(time_period), :merge_request_id),
            projects_imported_from_github: distinct_count(::Project.github_imported.where(time_period), :creator_id),
            projects_with_repositories_enabled: distinct_count(::Project.with_repositories_enabled.where(time_period),
                                                               :creator_id,
                                                               start: minimum_id(::User),
                                                               finish: maximum_id(::User)),
            protected_branches: distinct_count(::Project.with_protected_branches.where(time_period),
                                               :creator_id,
                                               start: minimum_id(::User),
                                               finish: maximum_id(::User)),
            users_using_path_locks: distinct_count(PathLock.where(time_period), :user_id),
            users_using_lfs_locks: distinct_count(LfsFileLock.where(time_period), :user_id),
            total_number_of_path_locks: count(::PathLock.where(time_period)),
            total_number_of_locked_files: count(::LfsFileLock.where(time_period))
          }, approval_rules_counts)
        end

        override :usage_activity_by_stage_enablement
        def usage_activity_by_stage_enablement(time_period)
          return super unless ::Gitlab::Geo.enabled?

          super.merge({
                      geo_secondary_web_oauth_users: distinct_count(
                        OauthAccessGrant
                            .where(time_period)
                            .where(
                              application_id: GeoNode.secondary_nodes.select(:oauth_application_id)
                            ),
                        :resource_owner_id
                      ),
                      # rubocop: disable UsageData/LargeTable
                      # These fields are pre-calculated on the secondary for transmission and storage on the primary.
                      # This will end up as an array of hashes with the data from GeoNodeStatus, see
                      # https://docs.gitlab.com/ee/api/geo_nodes.html#retrieve-status-about-a-specific-geo-node for what
                      # that inner hash may contain
                      # For Example:
                      # geo_node_usage: [
                      #   {
                      #     repositories_count: 10,
                      #     repositories_synced_count: 5,
                      #     repositories_failed_count: 0,
                      #     ... other geo node status fields
                      #   }
                      # ]
                      geo_node_usage: GeoNodeStatus.for_active_secondaries.map do |node|
                        GeoNodeStatus::RESOURCE_STATUS_FIELDS.to_h { |field| [field, node[field]] }
                      end
                    # rubocop: enable UsageData/LargeTable
                  })
        end

        # Omitted because no user, creator or author associated: `campaigns_imported_from_github`, `ldap_group_links`
        override :usage_activity_by_stage_manage
        def usage_activity_by_stage_manage(time_period)
          super.merge({
            ldap_keys: distinct_count(::LDAPKey.where(time_period), :user_id),
            ldap_users: distinct_count(::GroupMember.of_ldap_type.where(time_period), :user_id),
            value_stream_management_customized_group_stages: count(::Analytics::CycleAnalytics::GroupStage.where(custom: true)),
            projects_with_compliance_framework: count(::ComplianceManagement::ComplianceFramework::ProjectSettings),
            custom_compliance_frameworks: count(::ComplianceManagement::Framework),
            compliance_frameworks_with_pipeline: count(::ComplianceManagement::Framework.where.not(pipeline_configuration_full_path: nil)),
            ldap_servers: ldap_available_servers.size,
            ldap_group_sync_enabled: ldap_config_present_for_any_provider?(:group_base),
            ldap_admin_sync_enabled: ldap_config_present_for_any_provider?(:admin_group),
            group_saml_enabled: omniauth_provider_names.include?('group_saml')
          })
        end

        override :usage_activity_by_stage_monitor
        def usage_activity_by_stage_monitor(time_period)
          super.merge({
            operations_dashboard_users_with_projects_added: distinct_count(UsersOpsDashboardProject.joins(:user).merge(::User.active).where(time_period), :user_id),
            projects_incident_sla_enabled: time_period.present? ? ::Gitlab::UsageData::DEPRECATED_VALUE : count(::Project.with_enabled_incident_sla)
          })
        end

        # Omitted because no user, creator or author associated: `boards`, `labels`, `milestones`, `uploads`
        # Omitted because too expensive: `epics_deepest_relationship_level`
        # Omitted because of encrypted properties: `projects_jira_cloud_active`, `projects_jira_server_active`
        override :usage_activity_by_stage_plan
        def usage_activity_by_stage_plan(time_period)
          super.merge({
            assignee_lists: distinct_count(::List.assignee.where(time_period), :user_id),
            epics: distinct_count(::Epic.where(time_period), :author_id),
            label_lists: distinct_count(::List.label.where(time_period), :user_id),
            milestone_lists: distinct_count(::List.milestone.where(time_period), :user_id)
          })
        end

        # Omitted because no user, creator or author associated: `environments`, `feature_flags`, `in_review_folder`, `pages_domains`
        override :usage_activity_by_stage_release
        def usage_activity_by_stage_release(time_period)
          super.merge({
            projects_mirrored_with_pipelines_enabled: distinct_count(::Project.mirrored_with_enabled_pipelines.where(time_period), :creator_id)
          })
        end

        # Omitted because no user, creator or author associated: `ci_runners`
        override :usage_activity_by_stage_verify
        def usage_activity_by_stage_verify(time_period)
          super.merge({
            projects_reporting_ci_cd_back_to_github: distinct_count(::Project.with_github_integration_pipeline_events.where(time_period), :creator_id)
          })
        end

        # Currently too complicated and to get reliable counts for these stats:
        # container_scanning_jobs, dast_jobs, dependency_scanning_jobs, license_management_jobs, sast_jobs, secret_detection_jobs, coverage_fuzzing_jobs
        # Once https://gitlab.com/gitlab-org/gitlab/merge_requests/17568 is merged, this might be doable
        override :usage_activity_by_stage_secure
        def usage_activity_by_stage_secure(time_period)
          prefix = 'user_'

          results = {
            user_preferences_group_overview_security_dashboard: count(::User.active.group_view_security_dashboard.where(time_period))
          }

          SECURE_PRODUCT_TYPES.each do |secure_type, attribs|
            results["#{prefix}#{attribs[:name]}".to_sym] = distinct_count(::Ci::Build.where(name: secure_type).where(time_period),
                                                                          :user_id,
                                                                          start: minimum_id(::User),
                                                                          finish: maximum_id(::User))
          end

          results.merge!(count_secure_user_scans(time_period))
          results.merge!(count_secure_pipelines(time_period))
          results.merge!(count_secure_scans(time_period))

          results[:"#{prefix}unique_users_all_secure_scanners"] = distinct_count(::Ci::Build.where(name: SECURE_PRODUCT_TYPES.keys).where(time_period), :user_id)

          # handle license rename https://gitlab.com/gitlab-org/gitlab/issues/8911
          combined_license_key = "#{prefix}license_management_jobs".to_sym
          license_scan_count = results.delete("#{prefix}license_scanning_jobs".to_sym)
          results[combined_license_key] += license_scan_count > 0 ? license_scan_count : 0 if license_scan_count.is_a?(Integer)

          super.merge(results)
        end
        # rubocop:enable CodeReuse/ActiveRecord

        private

        # rubocop:disable UsageData/LargeTable
        # rubocop:disable CodeReuse/ActiveRecord
        def count_secure_user_scans(time_period)
          return {} if time_period.blank?

          user_scans = {}
          start_id, finish_id = min_max_security_scan_id(time_period)

          ::Security::Scan.scan_types.each do |name, scan_type|
            relation = ::Security::Scan
                         .latest_successful_by_build
                         .by_scan_types(scan_type)
                         .where(security_scans: time_period)

            if start_id && finish_id
              user_scans["user_#{name}_scans".to_sym] = estimate_batch_distinct_count(relation, :user_id, batch_size: 1000, start: start_id, finish: finish_id)
            end
          end

          user_scans
        end
        # rubocop:enable UsageData/LargeTable
        # rubocop:enable CodeReuse/ActiveRecord

        # rubocop:disable CodeReuse/ActiveRecord
        # rubocop: disable UsageData/LargeTable
        def count_secure_scans(time_period)
          start = minimum_id(::Security::Scan, :build_id)
          finish = maximum_id(::Security::Scan, :build_id)

          {}.tap do |secure_jobs|
            ::Security::Scan.scan_types.each do |name, scan_type|
              secure_jobs["#{name}_scans".to_sym] = count(::Security::Scan.joins(:build)
                .where(scan_type: scan_type)
                .merge(::CommitStatus.latest.success)
                .where(time_period), :build_id, start: start, finish: finish)
            end
          end
        end

        def count_secure_pipelines(time_period)
          return {} if time_period.blank?

          pipelines_with_secure_jobs = {}

          start_id, finish_id = min_max_security_scan_id(time_period)

          ::Security::Scan.scan_types.each do |name, scan_type|
            relation = ::Security::Scan
                         .latest_successful_by_build
                         .by_scan_types(scan_type)
                         .where(security_scans: time_period)

            metric_name = "#{name}_pipeline"
            aggregated_metrics_params = {
              metric_name: metric_name,
              recorded_at_timestamp: recorded_at,
              time_period: time_period
            }

            pipelines_with_secure_jobs[metric_name.to_sym] =
              if start_id && finish_id
                estimate_batch_distinct_count(relation, :commit_id, batch_size: 1000, start: start_id, finish: finish_id) do |result|
                  ::Gitlab::Usage::Metrics::Aggregates::Sources::PostgresHll
                    .save_aggregated_metrics(**aggregated_metrics_params.merge({ data: result }))
                end
              else
                ::Gitlab::Usage::Metrics::Aggregates::Sources::PostgresHll
                  .save_aggregated_metrics(**aggregated_metrics_params.merge({ data: ::Gitlab::Database::PostgresHll::Buckets.new }))
                0
              end
          end
          pipelines_with_secure_jobs
        end

        def min_max_security_scan_id(time_period)
          scans_table = ::Security::Scan.arel_table
          inner_relation = ::Security::Scan.select(:id)
                             .where(
                               to_date_arel_node(Arel.sql('date_range_source'))
                                 .eq(to_date_arel_node(scans_table[time_period.keys[0]]))
                             )

          outer_relation = ::Security::Scan
                             .from("generate_series(
                                '#{time_period.values[0].first.to_time.to_s(:db)}'::timestamp,
                                '#{time_period.values[0].last.to_time.to_s(:db)}'::timestamp,
                                '1 day'::interval) date_range_source")

          start_id = outer_relation
                       .select("(#{inner_relation.order(id: :asc).limit(1).to_sql})")
                       .order('1 ASC NULLS LAST')
                       .first&.id

          finish_id = outer_relation
                        .select("(#{inner_relation.order(id: :desc).limit(1).to_sql})")
                        .order('1 DESC NULLS LAST')
                        .first&.id

          [start_id, finish_id]
        end
        # rubocop: enable UsageData/LargeTable

        def to_date_arel_node(column)
          locked_timezone = Arel::Nodes::NamedFunction.new('TIMEZONE', [Arel.sql("'UTC'"), column])
          Arel::Nodes::NamedFunction.new('DATE', [locked_timezone])
        end

        def ldap_config_present_for_any_provider?(configuration_item)
          ldap_available_servers.any? { |server_config| server_config[configuration_item.to_s] }
        end

        def ldap_available_servers
          ::Gitlab::Auth::Ldap::Config.available_servers
        end

        def merge_requests_with_overridden_project_rules(time_period = nil)
          sql =
            <<~SQL
              (EXISTS (
                SELECT
                  1
                FROM
                  approval_merge_request_rule_sources
                WHERE
                  approval_merge_request_rule_sources.approval_merge_request_rule_id = approval_merge_request_rules.id
                  AND NOT EXISTS (
                    SELECT
                      1
                    FROM
                      approval_project_rules
                    WHERE
                      approval_project_rules.id = approval_merge_request_rule_sources.approval_project_rule_id
                      AND EXISTS (
                        SELECT
                          1
                        FROM
                          projects
                        WHERE
                          projects.id = approval_project_rules.project_id
                          AND projects.disable_overriding_approvers_per_merge_request = FALSE))))
                  OR("approval_merge_request_rules"."modified_from_project_rule" = TRUE)
            SQL

          distinct_count(
            ::ApprovalMergeRequestRule.where(time_period).where(sql),
            :merge_request_id,
            start: minimum_id(::ApprovalMergeRequestRule, :merge_request_id),
            finish: maximum_id(::ApprovalMergeRequestRule, :merge_request_id)
          )
        end

        def projects_jira_issuelist_active
          # rubocop: disable UsageData/LargeTable:
          min_id = minimum_id(::Integrations::JiraTrackerData.where(issues_enabled: true), :service_id)
          max_id = maximum_id(::Integrations::JiraTrackerData.where(issues_enabled: true), :service_id)
          # rubocop: enable UsageData/LargeTable:
          count(::Integrations::Jira.active.includes(:jira_tracker_data).where(jira_tracker_data: { issues_enabled: true }), start: min_id, finish: max_id)
        end
        # rubocop:enable CodeReuse/ActiveRecord

        # rubocop:disable CodeReuse/ActiveRecord
        def projects_with_sectional_code_owner_rules(time_period)
          distinct_count(
            ::ApprovalMergeRequestRule
              .code_owner
              .joins(:merge_request)
              .where.not(section: ::Gitlab::CodeOwners::Entry::DEFAULT_SECTION)
              .where(time_period),
            'merge_requests.target_project_id',
            start: minimum_id(::Project),
            finish: maximum_id(::Project)
          )
        end
        # rubocop:enable CodeReuse/ActiveRecord

        override :clear_memoized
        def clear_memoized
          super

          EE_MEMOIZED_VALUES.each { |v| clear_memoization(v) }
        end
      end
    end
  end
end
