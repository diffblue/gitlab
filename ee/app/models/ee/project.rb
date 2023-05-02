# frozen_string_literal: true

module EE
  # Project EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Project` model
  module Project
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override
    extend ::Gitlab::Cache::RequestCache
    include ::Gitlab::Utils::StrongMemoize
    include ::Admin::RepoSizeLimitHelper
    include ::Ai::Model
    include FromUnion

    GIT_LFS_DOWNLOAD_OPERATION = 'download'
    ISSUE_BATCH_SIZE = 500

    module FilterByBranch
      def applicable_to_branch(branch)
        includes(:protected_branches).select { |rule| rule.applies_to_branch?(branch) }
      end

      def inapplicable_to_branch(branch)
        includes(:protected_branches).reject { |rule| rule.applies_to_branch?(branch) }
      end
    end

    prepended do
      include Elastic::ProjectsSearch
      include EachBatch
      include InsightsFeature
      include DeprecatedApprovalsBeforeMerge
      include UsageStatistics
      include ProjectSecurityScannersInformation
      include VulnerabilityFlagHelpers
      include MirrorConfiguration

      before_update :update_legacy_open_source_license_available, if: -> { visibility_level_changed? }

      before_save :set_override_pull_mirror_available, unless: -> { ::Gitlab::CurrentSettings.mirror_available }
      before_save :set_next_execution_timestamp_to_now, if: ->(project) { project.mirror? && project.mirror_changed? && project.import_state }

      after_create :create_security_setting, unless: :security_setting

      belongs_to :mirror_user, class_name: 'User'
      belongs_to :deleting_user, foreign_key: 'marked_for_deletion_by_user_id', class_name: 'User'

      has_one :repository_state, class_name: 'ProjectRepositoryState', inverse_of: :project
      has_one :wiki_repository, class_name: 'Projects::WikiRepository', inverse_of: :project
      has_one :project_registry, class_name: 'Geo::ProjectRegistry', inverse_of: :project
      has_one :push_rule, ->(project) { project&.feature_available?(:push_rules) ? all : none }, inverse_of: :project
      has_one :index_status

      has_one :github_integration, class_name: 'Integrations::Github'
      has_one :gitlab_slack_application_integration, class_name: 'Integrations::GitlabSlackApplication'

      has_one :status_page_setting, inverse_of: :project, class_name: 'StatusPage::ProjectSetting'
      has_one :compliance_framework_setting, class_name: 'ComplianceManagement::ComplianceFramework::ProjectSettings', inverse_of: :project
      has_one :compliance_management_framework, through: :compliance_framework_setting, source: 'compliance_management_framework'
      has_one :security_setting, class_name: 'ProjectSecuritySetting'
      has_one :vulnerability_statistic, class_name: 'Vulnerabilities::Statistic'

      has_many :approvers, as: :target, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
      has_many :approver_users, through: :approvers, source: :user
      has_many :approver_groups, as: :target, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
      has_many :approval_rules, class_name: 'ApprovalProjectRule', extend: FilterByBranch
      # NOTE: This was added to avoid N+1 queries when we load list of MergeRequests
      has_many :regular_or_any_approver_approval_rules, -> { regular_or_any_approver.order(rule_type: :desc, id: :asc) }, class_name: 'ApprovalProjectRule', extend: FilterByBranch
      has_many :external_status_checks, class_name: 'MergeRequests::ExternalStatusCheck'
      has_many :approval_merge_request_rules, through: :merge_requests, source: :approval_rules
      has_many :audit_events, as: :entity
      has_many :path_locks
      has_many :requirements, inverse_of: :project, class_name: 'RequirementsManagement::Requirement'
      has_many :dast_scanner_profiles

      # the rationale behind vulnerabilities and vulnerability_findings can be found here:
      # https://gitlab.com/gitlab-org/gitlab/issues/10252#terminology
      has_many :vulnerabilities, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
      has_many :vulnerability_reads, class_name: 'Vulnerabilities::Read'
      has_many :vulnerability_feedback, class_name: 'Vulnerabilities::Feedback'
      has_many :vulnerability_historical_statistics, class_name: 'Vulnerabilities::HistoricalStatistic'
      has_many :vulnerability_findings,
               class_name: 'Vulnerabilities::Finding',
               inverse_of: :project, dependent: :destroy do # rubocop:disable Cop/ActiveRecordDependent
        def lock_for_confirmation!(id)
          where(vulnerability_id: nil).lock.find(id)
        end
      end
      has_many :vulnerability_identifiers, class_name: 'Vulnerabilities::Identifier'
      has_many :vulnerability_scanners, class_name: 'Vulnerabilities::Scanner'
      has_many :vulnerability_exports, class_name: 'Vulnerabilities::Export'
      has_many :vulnerability_remediations, class_name: 'Vulnerabilities::Remediation', inverse_of: :project

      has_many :dast_site_profiles
      has_many :dast_site_tokens
      has_many :dast_sites
      has_many :dast_profiles, class_name: 'Dast::Profile'

      has_many :protected_environments
      has_many :software_license_policies, inverse_of: :project, class_name: 'SoftwareLicensePolicy'
      has_many :software_licenses, through: :software_license_policies
      accepts_nested_attributes_for :software_license_policies, allow_destroy: true
      has_many :merge_train_cars, class_name: 'MergeTrains::Car', foreign_key: 'target_project_id', inverse_of: :target_project

      has_many :project_aliases

      has_many :upstream_project_subscriptions, class_name: 'Ci::Subscriptions::Project', foreign_key: :downstream_project_id, inverse_of: :downstream_project
      has_many :upstream_projects, class_name: 'Project', through: :upstream_project_subscriptions, source: :upstream_project, disable_joins: true
      has_many :downstream_project_subscriptions, class_name: 'Ci::Subscriptions::Project', foreign_key: :upstream_project_id, inverse_of: :upstream_project

      has_many :incident_management_oncall_schedules, class_name: 'IncidentManagement::OncallSchedule', inverse_of: :project
      has_many :incident_management_oncall_rotations, class_name: 'IncidentManagement::OncallRotation', through: :incident_management_oncall_schedules, source: :rotations
      has_many :incident_management_escalation_policies, class_name: 'IncidentManagement::EscalationPolicy', inverse_of: :project

      has_one :security_orchestration_policy_configuration, class_name: 'Security::OrchestrationPolicyConfiguration', foreign_key: :project_id, inverse_of: :project

      has_many :security_scans, class_name: 'Security::Scan', inverse_of: :project
      has_many :security_trainings, class_name: 'Security::Training', inverse_of: :project

      has_many :dependency_list_exports, class_name: 'Dependencies::DependencyListExport', inverse_of: :project

      has_many :vulnerability_hooks_integrations, -> { vulnerability_hooks }, class_name: 'Integration'

      has_many :sbom_occurrences, inverse_of: :project, class_name: 'Sbom::Occurrence'

      has_one :analytics_dashboards_pointer, class_name: 'Analytics::DashboardsPointer', foreign_key: :project_id
      accepts_nested_attributes_for :analytics_dashboards_pointer, allow_destroy: true
      has_one :analytics_dashboards_configuration_project, through: :analytics_dashboards_pointer, source: :target_project

      elastic_index_dependant_association :issues, on_change: :visibility_level
      elastic_index_dependant_association :merge_requests, on_change: :visibility_level
      elastic_index_dependant_association :notes, on_change: :visibility_level

      scope :mirror, -> { where(mirror: true) }

      scope :mirrors_to_sync, ->(freeze_at, limit: nil) do
        mirror
          .joins_import_state
          .where.not(import_state: { status: [:scheduled, :started] })
          .where("import_state.next_execution_timestamp <= ?", freeze_at)
          .where("import_state.retry_count <= ?", ::Gitlab::Mirror::MAX_RETRY)
          .limit(limit)
      end

      scope :with_hard_import_failures, -> do
        joins_import_state
          .where(import_state: { status: [:failed] })
          .where('import_state.retry_count > ?', ::Gitlab::Mirror::MAX_RETRY)
      end

      scope :with_coverage_feature_usage, ->(default_branch: nil) do
        join_conditions = { feature: :code_coverage }
        join_conditions[:default_branch] = default_branch unless default_branch.nil?

        joins(:ci_feature_usages).where(ci_feature_usages: join_conditions).group(:id)
      end

      scope :with_wiki_enabled, -> { with_feature_enabled(:wiki) }
      scope :within_shards, -> (shard_names) { where(repository_storage: Array(shard_names)) }
      scope :verification_failed_repos, -> { joins(:repository_state).merge(ProjectRepositoryState.verification_failed_repos) }
      scope :verification_failed_wikis, -> { joins(:repository_state).merge(ProjectRepositoryState.verification_failed_wikis) }
      scope :for_plan_name, -> (name) { joins(namespace: { gitlab_subscription: :hosted_plan }).where(plans: { name: name }) }
      scope :with_feature_available, -> (name) do
        paid_groups = ::Group.with_feature_available_in_plan(name)
        # subgroups of a paid group inherit paid features of the root group,
        # and hence we must also include projects from such subgroups.
        projects_with_feature_available_in_plan = ::Project.for_group_and_its_subgroups(paid_groups)
        public_projects_in_public_groups = ::Project.public_only.for_group(::Group.public_only)

        from_union([projects_with_feature_available_in_plan, public_projects_in_public_groups])
      end
      scope :requiring_code_owner_approval,
            -> { joins(:protected_branches).where(protected_branches: { code_owner_approval_required: true }) }
      scope :github_imported, -> { where(import_type: 'github') }
      scope :with_protected_branches, -> { joins(:protected_branches) }
      scope :with_repositories_enabled, -> { joins(:project_feature).where(project_features: { repository_access_level: ::ProjectFeature::ENABLED }) }

      scope :with_security_reports_stored, -> { where('EXISTS (?)', ::Vulnerabilities::Finding.scoped_project.select(1)) }
      scope :with_security_scans, -> { where('EXISTS (?)', Security::Scan.scoped_project.select(1)) }
      scope :with_github_integration_pipeline_events, -> { joins(:github_integration).merge(::Integrations::Github.pipeline_hooks) }
      scope :with_active_prometheus_integration, -> { joins(:prometheus_integration).merge(::Integrations::Prometheus.active) }
      scope :mirrored_with_enabled_pipelines, -> do
        joins(:project_feature).mirror.where(mirror_trigger_builds: true,
                                             project_features: { builds_access_level: ::ProjectFeature::ENABLED })
      end
      scope :with_slack_integration, -> { joins(:slack_integration) }
      scope :with_slack_slash_commands_integration, -> { joins(:slack_slash_commands_integration) }
      scope :aimed_for_deletion, -> (date) { where('marked_for_deletion_at <= ?', date).without_deleted }
      scope :with_repos_templates, -> { where(namespace_id: ::Gitlab::CurrentSettings.current_application_settings.custom_project_templates_group_id) }
      scope :with_groups_level_repos_templates, -> { joins("INNER JOIN namespaces ON projects.namespace_id = namespaces.custom_project_templates_group_id") }
      scope :with_designs, -> { where(id: ::DesignManagement::Design.select(:project_id).distinct) }
      scope :with_deleting_user, -> { includes(:deleting_user) }
      scope :with_compliance_framework_settings, -> { preload(:compliance_framework_setting) }
      scope :has_vulnerabilities, -> { joins(:project_setting).merge(::ProjectSetting.has_vulnerabilities) }
      scope :has_vulnerability_statistics, -> { joins(:vulnerability_statistic) }
      scope :with_vulnerability_statistics, -> { includes(:vulnerability_statistic) }

      scope :with_group_saml_provider, -> { preload(group: :saml_provider) }

      scope :with_total_repository_size_greater_than, -> (value) do
        statistics = ::ProjectStatistics.arel_table

        joins(:statistics)
          .where((statistics[:repository_size] + statistics[:lfs_objects_size]).gt(value))
      end
      scope :without_unlimited_repository_size_limit, -> { where.not(repository_size_limit: 0) }
      scope :without_repository_size_limit, -> { where(repository_size_limit: nil) }
      scope :with_legacy_open_source_license, -> (available) do
        joins(:project_setting)
          .where('project_settings.legacy_open_source_license_available' => available)
      end

      # Less storage left (compared to repo storage limit) means
      # project will be higher on the list.
      scope :order_by_excess_repo_storage_size_desc, -> (limit = 0) do
        excess_repo_storage_size_arel = ::ProjectStatistics.arel_table[:repository_size] +
          ::ProjectStatistics.arel_table[:lfs_objects_size] -
          arel_table.coalesce(arel_table[:repository_size_limit], limit)

        order = ::Gitlab::Pagination::Keyset::Order.build(
          [
            ::Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: 'excess_repo_storage_size',
              order_expression: excess_repo_storage_size_arel.desc,
              add_to_projections: true,
              distinct: false
            ),
            ::Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: 'projects_id',
              order_expression: arel_table[:id].desc,
              add_to_projections: true,
              nullable: :not_nullable,
              distinct: true
            )
          ])

        order.apply_cursor_conditions(joins(:statistics)).order(order)
      end

      scope :order_by_storage_size, -> (direction) do
        build_keyset_order_on_joined_column(
          scope: joins(:statistics),
          attribute_name: 'project_statistics_storage_size',
          column: ::ProjectStatistics.arel_table[:storage_size],
          direction: direction,
          nullable: :nulls_first
        )
      end

      scope :with_project_setting, -> { includes(:project_setting) }

      scope :compliance_framework_id_in, -> (ids) do
        joins(:compliance_framework_setting).where(compliance_framework_setting: { framework_id: ids })
      end

      scope :compliance_framework_id_not_in, -> (ids) do
        left_outer_joins(:compliance_framework_setting).where.not(compliance_framework_setting: { framework_id: ids }).or(
          left_outer_joins(:compliance_framework_setting).where(compliance_framework_setting: { framework_id: nil }))
      end

      scope :missing_compliance_framework, -> { where.missing(:compliance_framework_setting) }

      scope :any_compliance_framework, -> { joins(:compliance_framework_setting) }

      delegate :shared_runners_seconds, to: :statistics, allow_nil: true

      delegate :ci_minutes_usage, to: :shared_runners_limit_namespace

      delegate :merge_pipelines_enabled, :merge_pipelines_enabled=, to: :ci_cd_settings, allow_nil: true
      delegate :merge_trains_enabled, :merge_trains_enabled=, to: :ci_cd_settings, allow_nil: true

      delegate :auto_rollback_enabled, :auto_rollback_enabled=, to: :ci_cd_settings, allow_nil: true

      delegate :requirements_access_level, to: :project_feature, allow_nil: true
      delegate :pipeline_configuration_full_path, to: :compliance_management_framework, allow_nil: true
      alias_attribute :compliance_pipeline_configuration_full_path, :pipeline_configuration_full_path

      delegate :prevent_merge_without_jira_issue,
               :selective_code_owner_removals,
               :suggested_reviewers_enabled,
               :only_allow_merge_if_all_status_checks_passed,
               :only_allow_merge_if_all_status_checks_passed=,
               :mirror_branch_regex,
               :mirror_branch_regex=,
               :allow_pipeline_trigger_approve_deployment,
               :allow_pipeline_trigger_approve_deployment=,
               to: :project_setting

      validates :repository_size_limit,
        numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }
      validates :max_pages_size,
        numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true,
                        less_than: ::Gitlab::Pages::MAX_SIZE / 1.megabyte }

      validates :approvals_before_merge, numericality: true, allow_blank: false
      validate :import_url_inside_fork_network, if: :import_url_changed?

      with_options if: :mirror? do
        validates :import_url, presence: true
        validates :mirror_user, presence: true
      end

      accepts_nested_attributes_for :status_page_setting, update_only: true, allow_destroy: true
      accepts_nested_attributes_for :compliance_framework_setting, update_only: true, allow_destroy: true

      alias_attribute :fallback_approvals_required, :approvals_before_merge

      def jira_issue_association_required_to_merge_enabled?
        strong_memoize(:jira_issue_association_required_to_merge_enabled) do
          next false unless jira_issues_integration_available?
          next false unless jira_integration&.active?
          next false unless feature_available?(:jira_issue_association_enforcement)

          true
        end
      end

      def jira_vulnerabilities_integration_enabled?
        !!jira_integration&.jira_vulnerabilities_integration_enabled?
      end

      def configured_to_create_issues_from_vulnerabilities?
        !!jira_integration&.configured_to_create_issues_from_vulnerabilities?
      end

      def can_suggest_reviewers?
        suggested_reviewers_available? && suggested_reviewers_enabled
      end

      def suggested_reviewers_available?
        strong_memoize(:suggested_reviewers_available) do
          ::Gitlab.com? &&
            ::Feature.enabled?(:suggested_reviewers_control, self) &&
            licensed_feature_available?(:suggested_reviewers)
        end
      end

      def member_usernames_among(users)
        members_among(users).pluck(:username)
      end

      def custom_roles_enabled?
        return false unless group

        root_ancestor.custom_roles_enabled?
      end
    end

    def self.cascading_with_parent_namespace(attribute)
      define_method("#{attribute}_of_parent_group") do
        self.group&.namespace_settings&.public_send("#{attribute}?", inherit_group_setting: true)
      end

      define_method("#{attribute}?") do |inherit_group_setting: false|
        return super() unless licensed_feature_available?(:group_level_merge_checks_setting) && ::Feature.enabled?(:support_group_level_merge_checks_setting, self)

        if inherit_group_setting
          result = self.public_send(attribute) || public_send("#{attribute}_of_parent_group") # rubocop:disable GitlabSecurity/PublicSend
        else
          result = self.public_send(attribute) # rubocop:disable GitlabSecurity/PublicSend
        end

        !!result
      end

      define_method("#{attribute}_locked?") do
        return super() unless licensed_feature_available?(:group_level_merge_checks_setting) && ::Feature.enabled?(:support_group_level_merge_checks_setting, self)

        public_send("#{attribute}_of_parent_group") # rubocop:disable GitlabSecurity/PublicSend
      end
    end

    cascading_with_parent_namespace :only_allow_merge_if_pipeline_succeeds
    cascading_with_parent_namespace :allow_merge_on_skipped_pipeline
    cascading_with_parent_namespace :only_allow_merge_if_all_discussions_are_resolved

    def mirror_last_update_succeeded?
      !!import_state&.last_update_succeeded?
    end

    def mirror_last_update_failed?
      !!import_state&.last_update_failed?
    end

    def mirror_ever_updated_successfully?
      !!import_state&.ever_updated_successfully?
    end

    def mirror_hard_failed?
      !!import_state&.hard_failed?
    end

    class_methods do
      extend ::Gitlab::Utils::Override

      # @param primary_key_in [Range, Project] arg to pass to primary_key_in scope
      # @return [ActiveRecord::Relation<Project>] everything that should be synced to this node, restricted by primary key
      def replicables_for_current_secondary(primary_key_in)
        node = ::Gitlab::Geo.current_node

        node.projects.primary_key_in(primary_key_in)
      end

      def search_by_visibility(level)
        where(visibility_level: ::Gitlab::VisibilityLevel.string_options[level])
      end

      def with_slack_application_disabled
        # Using Arel to avoid exposing what the column backing the type: attribute is
        # rubocop: disable GitlabSecurity/PublicSend
        with_active_slack = ::Integration.active.by_name(:gitlab_slack_application)
        join_contraint = arel_table[:id].eq(::Integration.arel_table[:project_id])
        constraint = with_active_slack.where_clause.send(:predicates).reduce(join_contraint) { |a, b| a.and(b) }
        join = arel_table.join(::Integration.arel_table, Arel::Nodes::OuterJoin).on(constraint).join_sources
        # rubocop: enable GitlabSecurity/PublicSend

        joins(join).where(integrations: { id: nil })
      rescue ::Integration::UnknownType
        all
      end

      override :with_web_entity_associations
      def with_web_entity_associations
        super.preload(:compliance_framework_setting, group: [:ip_restrictions, :saml_provider])
      end

      override :with_api_entity_associations
      def with_api_entity_associations
        super.preload(group: [:ip_restrictions, :saml_provider])
      end

      override :inactive
      def inactive
        return super unless ::Gitlab.com?

        statistics = ::ProjectStatistics.arel_table
        minimum_size_mb = ::Gitlab::CurrentSettings.inactive_projects_min_size_mb.megabytes
        last_activity_cutoff = ::Gitlab::CurrentSettings.inactive_projects_send_warning_email_after_months.months.ago

        for_plan_name(::Plan.default_plans)
          .joins(:statistics)
          .where((statistics[:storage_size]).gt(minimum_size_mb))
          .where('last_activity_at < ?', last_activity_cutoff)
      end

      override :project_features_defaults
      def project_features_defaults
        super.merge(requirements: true)
      end
    end

    def can_store_security_reports?
      namespace.store_security_reports_available? || public?
    end

    def okrs_mvc_feature_flag_enabled?
      ::Feature.enabled?(:okrs_mvc, self)
    end

    def okr_automatic_rollups_enabled?
      ::Feature.enabled?(:okr_automatic_rollups, self)
    end

    def latest_ingested_security_pipeline
      vulnerability_statistic&.pipeline
    end

    def latest_default_branch_pipeline_with_reports(reports)
      latest_pipeline_with_reports_for_ref(default_branch, reports)
    end

    def latest_pipeline_with_reports_for_ref(ref, reports)
      all_pipelines.success.newest_first(ref: ref).with_reports(reports).take
    end

    def security_reports_up_to_date_for_ref?(ref)
      latest_ingested_security_pipeline == ci_pipelines.newest_first(ref: ref).take
    end

    def ensure_external_webhook_token
      return if external_webhook_token.present?

      self.external_webhook_token = Devise.friendly_token
    end

    def shared_runners_limit_namespace
      root_namespace
    end

    def mirror
      super && feature_available?(:repository_mirrors) && pull_mirror_available?
    end
    alias_method :mirror?, :mirror

    def mirror_with_content?
      mirror? && !empty_repo?
    end

    def fetch_mirror(forced: false, check_tags_changed: false)
      return unless mirror?

      # Only send the password if it's needed
      url =
        if import_data&.password_auth?
          import_url
        else
          username_only_import_url
        end

      repository.fetch_upstream(url, forced: forced, check_tags_changed: check_tags_changed)
    end

    def can_override_approvers?
      !disable_overriding_approvers_per_merge_request
    end

    def shared_runners_available?
      super && !ci_minutes_usage.minutes_used_up?
    end

    def link_pool_repository
      super
      repository.log_geo_updated_event
    end

    def object_pool_missing?
      has_pool_repository? && !pool_repository.object_pool.exists?
    end

    def shared_runners_minutes_limit_enabled?
      shared_runners_enabled? && shared_runners_limit_namespace.shared_runners_minutes_limit_enabled?
    end

    override :feature_available?
    def feature_available?(feature, user = nil)
      if ::ProjectFeature::FEATURES.include?(feature)
        super
      else
        licensed_feature_available?(feature, user)
      end
    end

    def jira_issues_integration_available?
      feature_available?(:jira_issues_integration)
    end

    def multiple_approval_rules_available?
      feature_available?(:multiple_approval_rules)
    end

    def code_owner_approval_required_available?
      feature_available?(:code_owner_approval_required)
    end

    def github_external_pull_request_pipelines_available?
      mirror? &&
        feature_available?(:ci_cd_projects) &&
        feature_available?(:github_integration)
    end

    override :add_import_job
    def add_import_job
      return if gitlab_custom_project_template_import?

      # Historically this was intended ensure `super` is only called
      # when a project is imported(usually on project creation only) so `repository_exists?`
      # check was added so that it does not stop mirroring if later on mirroring option is added to the project.
      return super if import? && !repository_exists?

      if mirror?
        ::Gitlab::Metrics.add_event(:mirrors_scheduled)

        job_id = RepositoryUpdateMirrorWorker.perform_async(self.id)

        log_import_activity(job_id, type: :mirror)

        job_id
      end
    end

    override :has_active_hooks?
    def has_active_hooks?(hooks_scope = :push_hooks)
      super || has_group_hooks?(hooks_scope)
    end

    def has_group_hooks?(hooks_scope = :push_hooks)
      strong_memoize_with(:has_group_hooks, hooks_scope) do
        break false unless group && feature_available?(:group_webhooks)

        group_hooks.hooks_for(hooks_scope).any?
      end
    end

    def execute_external_compliance_hooks(data)
      external_status_checks.each do |approval_rule|
        approval_rule.async_execute(data)
      end
    end

    override :execute_hooks
    def execute_hooks(data, hooks_scope = :push_hooks)
      super

      run_after_commit_or_now do
        if ::Feature.enabled?(:no_code_automation_mvc, self) && licensed_feature_available?(:no_code_automation)
          Automation::DispatchService.new(container: project_namespace).execute(data, hooks_scope)
        end
      end
    end

    override :triggered_hooks
    def triggered_hooks(scope, data)
      triggered = super
      triggered.add_hooks(group_hooks) if group && feature_available?(:group_webhooks)

      triggered
    end

    # No need to have a Kerberos Web url. Kerberos URL will be used only to
    # clone
    def kerberos_url_to_repo
      "#{::Gitlab.config.build_gitlab_kerberos_url + ::Gitlab::Routing.url_helpers.project_path(self)}.git"
    end

    def group_ldap_synced?
      group&.ldap_synced?
    end

    override :allowed_to_share_with_group?
    def allowed_to_share_with_group?
      super && !(group && lock_memberships_to_ldap_or_saml?)
    end

    override :membership_locked?
    def membership_locked?
      return false unless group

      group.membership_lock?
    end

    # TODO: Clean up this method in the https://gitlab.com/gitlab-org/gitlab/issues/33329
    def approvals_before_merge
      return 0 unless feature_available?(:merge_request_approvers)

      super
    end

    def applicable_approval_rules_for_user(user_id, target_branch = nil)
      visible_approval_rules(target_branch: target_branch).select do |rule|
        rule.approvers.pluck(:id).include?(user_id)
      end
    end

    def visible_approval_rules(target_branch: nil)
      rules = strong_memoize(:visible_approval_rules) do
        Hash.new do |h, key|
          h[key] = visible_user_defined_rules(branch: key) + approval_rules.report_approver_without_scan_finding
        end
      end

      rules[target_branch]
    end

    def visible_user_defined_rules(branch: nil)
      return user_defined_rules.take(1) unless multiple_approval_rules_available?
      return user_defined_rules unless branch

      rules = strong_memoize(:visible_user_defined_rules) do
        Hash.new do |h, key|
          h[key] = user_defined_rules.applicable_to_branch(key)
        end
      end

      rules[branch]
    end

    def visible_user_defined_inapplicable_rules(branch)
      return [] unless multiple_approval_rules_available?

      user_defined_rules.inapplicable_to_branch(branch)
    end

    # TODO: Clean up this method in the https://gitlab.com/gitlab-org/gitlab/issues/33329
    def min_fallback_approvals
      strong_memoize(:min_fallback_approvals) do
        visible_user_defined_rules.map(&:approvals_required).max.to_i
      end
    end

    def reset_approvals_on_push
      !ComplianceManagement::MergeRequestApprovalSettings::Resolver.new(group&.root_ancestor, project: self)
                                                                  .retain_approvals_on_push
                                                                  .value && feature_available?(:merge_request_approvers)
    end
    alias_method :reset_approvals_on_push?, :reset_approvals_on_push

    def approver_ids=(value)
      ::Gitlab::Utils.ensure_array_from_string(value).each do |user_id|
        approvers.find_or_create_by(user_id: user_id, target_id: id)
      end
    end

    def approver_group_ids=(value)
      ::Gitlab::Utils.ensure_array_from_string(value).each do |group_id|
        approver_groups.find_or_initialize_by(group_id: group_id, target_id: id)
      end
    end

    def merge_requests_require_code_owner_approval?
      code_owner_approval_required_available? &&
        protected_branches.requiring_code_owner_approval.any?
    end

    def branch_requires_code_owner_approval?(branch_name)
      return false unless code_owner_approval_required_available?

      ::ProtectedBranch.branch_requires_code_owner_approval?(self, branch_name)
    end

    def require_password_to_approve
      ComplianceManagement::MergeRequestApprovalSettings::Resolver.new(group&.root_ancestor, project: self)
                                                                  .require_password_to_approve
                                                                  .value && password_authentication_enabled_for_web?
    end

    def require_password_to_approve?
      !!require_password_to_approve
    end

    def find_path_lock(path, exact_match: false, downstream: false)
      path_lock_finder = strong_memoize(:path_lock_finder) do
        ::Gitlab::PathLocksFinder.new(self)
      end

      path_lock_finder.find(path, exact_match: exact_match, downstream: downstream)
    end

    def import_url_updated?
      # check if import_url has been updated and it's not just the first assignment
      saved_change_to_import_url? && saved_changes['import_url'].first
    end

    def username_only_import_url
      bare_url = read_attribute(:import_url)
      return bare_url unless ::Gitlab::UrlSanitizer.valid?(bare_url)

      ::Gitlab::UrlSanitizer.new(bare_url, credentials: { user: import_data&.user }).full_url
    end

    def actual_size_limit
      strong_memoize(:actual_size_limit) do
        repository_size_limit || namespace.actual_size_limit
      end
    end

    def repository_size_checker
      strong_memoize(:repository_size_checker) do
        root_namespace = namespace.root_ancestor

        if ::Namespaces::Storage::Enforcement.enforce_limit?(root_namespace)
          ::Namespaces::Storage::RootSize.new(root_namespace)
        else
          ::Gitlab::RepositorySizeChecker.new(
            current_size_proc: -> { statistics.total_repository_size },
            limit: actual_size_limit,
            namespace: namespace,
            enabled: repo_size_limit_feature_available?
          )
        end
      end
    end

    def product_analytics_enabled?
      return false unless licensed_feature_available?(:product_analytics)
      return false unless ::Feature.enabled?(:product_analytics_dashboards, self)

      true
    end

    def product_analytics_dashboards
      return [] unless product_analytics_enabled?

      ::ProductAnalytics::Dashboard.for_project(self.analytics_dashboards_configuration_project || self)
    end

    def product_analytics_funnels
      return [] unless product_analytics_enabled?

      ::ProductAnalytics::Funnel.for_project(self)
    end

    def product_analytics_dashboard(slug)
      return [] unless product_analytics_enabled?

      ::ProductAnalytics::Dashboard.for_project(self).find { |dashboard| dashboard.slug == slug }
    end

    def repository_size_excess
      return 0 unless actual_size_limit.to_i > 0

      [statistics.total_repository_size - actual_size_limit, 0].max
    end

    def username_only_import_url=(value)
      unless ::Gitlab::UrlSanitizer.valid?(value)
        self.import_url = value
        self.import_data&.user = nil
        return
      end

      url = ::Gitlab::UrlSanitizer.new(value)
      creds = url.credentials.slice(:user)

      write_attribute(:import_url, url.sanitized_url)
      create_or_update_import_data(credentials: creds)

      username_only_import_url
    end

    def remove_import_data
      super unless mirror?
    end

    override :disabled_integrations
    def disabled_integrations
      strong_memoize(:disabled_integrations) do
        gh = github_integration_enabled? ? [] : %w[github]
        slack = if Rails.env.development?
                  []
                elsif ::Gitlab::CurrentSettings.slack_app_enabled
                  %w[slack_slash_commands]
                else
                  %w[gitlab_slack_application]
                end

        super + gh + slack
      end
    end

    def pull_mirror_available?
      pull_mirror_available_overridden ||
        ::Gitlab::CurrentSettings.mirror_available
    end

    override :licensed_features
    def licensed_features
      return super unless License.current

      License.current.features.select do |feature|
        GitlabSubscriptions::Features.global?(feature) || licensed_feature_available?(feature)
      end
    end

    def any_path_locks?
      path_locks.any?
    end
    request_cache(:any_path_locks?) { self.id }

    override :after_import
    def after_import
      super

      # Index the wiki repository after import of non-forked projects only, the project repository is indexed
      # in ProjectImportState so ElasticSearch will get project repository changes when mirrors are updated
      ElasticCommitIndexerWorker.perform_async(id, true) if use_elasticsearch? && !forked?
    end

    def use_zoekt?
      # Only use Zoekt for public repositories since right now Zoekt does not support permissions
      return false unless self.public? && self.repository_access_level > ::ProjectFeature::PRIVATE

      ::Zoekt::IndexedNamespace.enabled_for_project?(self)
    end

    def elastic_namespace_ancestry
      namespace.elastic_namespace_ancestry + "p#{id}-"
    end

    def log_geo_updated_events
      repository.log_geo_updated_event

      if ::Geo::ProjectWikiRepositoryReplicator.enabled?
        wiki_repository.replicator.handle_after_update if wiki_repository
      else
        wiki.repository.log_geo_updated_event
      end

      design_repository.log_geo_updated_event
    end

    override :import?
    def import?
      super || gitlab_custom_project_template_import?
    end

    def gitlab_custom_project_template_import?
      import_type == 'gitlab_custom_project_template' &&
        ::Gitlab::CurrentSettings.custom_project_templates_enabled?
    end

    override :lfs_http_url_to_repo
    def lfs_http_url_to_repo(operation = nil)
      return super unless ::Gitlab::Geo.secondary_with_primary?
      return super if operation == GIT_LFS_DOWNLOAD_OPERATION # download always comes from secondary

      geo_primary_http_url_to_repo(self)
    end

    def adjourned_deletion?
      feature_available?(:adjourned_deletion_for_projects_and_groups) &&
        adjourned_deletion_configured?
    end

    def adjourned_deletion_configured?
      ::Gitlab::CurrentSettings.deletion_adjourned_period > 0 &&
        group_deletion_mode_configured?
    end

    def marked_for_deletion?
      marked_for_deletion_at.present? &&
        License.feature_available?(:adjourned_deletion_for_projects_and_groups)
    end

    def ancestor_marked_for_deletion
      return unless feature_available?(:adjourned_deletion_for_projects_and_groups)

      ancestors(hierarchy_order: :asc)
        .joins(:deletion_schedule).first
    end

    def disable_overriding_approvers_per_merge_request
      strong_memoize(:disable_overriding_approvers_per_merge_request) do
        super unless feature_available?(:admin_merge_request_approvers_rules)

        !ComplianceManagement::MergeRequestApprovalSettings::Resolver.new(group&.root_ancestor, project: self)
                                                                    .allow_overrides_to_approver_list_per_merge_request
                                                                    .value
      end
    end

    def disable_overriding_approvers_per_merge_request?
      !!disable_overriding_approvers_per_merge_request
    end

    def merge_requests_author_approval
      strong_memoize(:merge_requests_author_approval) do
        super unless feature_available?(:admin_merge_request_approvers_rules)

        ComplianceManagement::MergeRequestApprovalSettings::Resolver.new(group&.root_ancestor, project: self)
                                                                     .allow_author_approval
                                                                     .value
      end
    end

    def merge_requests_author_approval?
      !!merge_requests_author_approval
    end

    def merge_requests_disable_committers_approval
      strong_memoize(:merge_requests_disable_committers_approval) do
        super unless feature_available?(:admin_merge_request_approvers_rules)

        !ComplianceManagement::MergeRequestApprovalSettings::Resolver.new(group&.root_ancestor, project: self)
                                                                     .allow_committer_approval
                                                                     .value
      end
    end

    def merge_requests_disable_committers_approval?
      !!merge_requests_disable_committers_approval
    end

    def license_compliance(pipeline = nil)
      pipeline ||= ::Gitlab::LicenseScanning.scanner_for_project(self).pipeline
      SCA::LicenseCompliance.new(self, pipeline)
    end

    override :template_source?
    def template_source?
      return true if namespace_id == ::Gitlab::CurrentSettings.current_application_settings.custom_project_templates_group_id

      ::Project.with_groups_level_repos_templates.exists?(id)
    end

    override :predefined_variables
    def predefined_variables
      strong_memoize(:ee_predefined_variables) do
        super.concat(requirements_ci_variables)
      end
    end

    def add_template_export_job(current_user:, after_export_strategy: nil, params: {})
      job_id = ProjectTemplateExportWorker.perform_async(current_user.id, self.id, after_export_strategy, params)

      if job_id
        ::Gitlab::AppLogger.info(message: 'Template Export job started', project_id: self.id, job_id: job_id)
      else
        ::Gitlab::AppLogger.error(message: 'Template Export job failed to start', project_id: self.id)
      end
    end

    def prevent_merge_without_jira_issue?
      jira_issue_association_required_to_merge_enabled? && prevent_merge_without_jira_issue
    end

    def licensed_feature_available?(feature, user = nil)
      available_features = strong_memoize(:licensed_feature_available) do
        Hash.new do |h, f|
          h[f] = load_licensed_feature_available(f)
        end
      end

      available_features[feature]
    end

    def upstream_projects_count
      upstream_project_subscriptions.count
    end

    def downstream_projects_count
      downstream_project_subscriptions.count
    end

    def merge_pipelines_enabled?
      return false unless ci_cd_settings

      ci_cd_settings.merge_pipelines_enabled?
    end

    def merge_pipelines_were_disabled?
      return false unless ci_cd_settings

      ci_cd_settings.merge_pipelines_were_disabled?
    end

    def merge_trains_enabled?
      return false unless ci_cd_settings

      ci_cd_settings.merge_trains_enabled?
    end

    def auto_rollback_enabled?
      return false unless ci_cd_settings

      ci_cd_settings.auto_rollback_enabled?
    end

    def all_security_orchestration_policy_configurations
      all_parent_groups = group&.self_and_ancestor_ids
      return [] if all_parent_groups.blank? && !security_orchestration_policy_configuration&.policy_configuration_valid?
      return Array.wrap(security_orchestration_policy_configuration) if all_parent_groups.blank?

      security_policies = ::Security::OrchestrationPolicyConfiguration
        .for_project(id)
        .or(::Security::OrchestrationPolicyConfiguration.for_namespace(all_parent_groups))

      security_orchestration_policies_for_scope(security_policies)
    end

    def all_inherited_security_orchestration_policy_configurations
      all_parent_groups = group&.self_and_ancestor_ids
      return [] if all_parent_groups.blank?

      security_policies = ::Security::OrchestrationPolicyConfiguration.for_namespace(all_parent_groups)

      security_orchestration_policies_for_scope(security_policies)
    end

    override :inactive?
    def inactive?
      ::Gitlab.com? && root_namespace.paid? ? false : super
    end

    def epic_ids_referenced_by_issues
      epic_ids = Set.new
      issues.each_batch(of: ISSUE_BATCH_SIZE, column: :iid) do |batch|
        epic_ids += ::EpicIssue.where(issue_id: batch).limit(ISSUE_BATCH_SIZE).pluck(:epic_id)
      end

      epic_ids.to_a
    end

    def any_external_status_checks_not_passed?(merge_request)
      status_checks = external_status_checks.applicable_to_branch(merge_request.target_branch)
      return false if status_checks.empty?

      status_checks.any? { |check| check.status(merge_request, merge_request.diff_head_sha) != 'passed' }
    end

    def only_mirror_protected_branches_column
      only_mirror_protected_branches
    end

    def predefined_push_rule
      return push_rule if ::Feature.disabled?(:inherited_push_rule_for_project, self)
      return unless feature_available?(:push_rules)
      return push_rule if push_rule

      if group
        group.predefined_push_rule
      else
        PushRule.global
      end
    end

    def should_check_index_integrity?
      use_elasticsearch? && repository_exists? && !empty_repo?
    end

    def send_to_ai?
      public? && repository_access_level > ::ProjectFeature::PRIVATE
    end

    def resource_parent
      self
    end

    private

    def lock_memberships_to_ldap_or_saml?
      ::Gitlab::CurrentSettings.lock_memberships_to_ldap? ||
        ::Gitlab::CurrentSettings.lock_memberships_to_saml?
    end

    def update_legacy_open_source_license_available
      project_setting.legacy_open_source_license_available = false
    end

    def security_orchestration_policies_for_scope(scope)
      scope
        .with_project_and_namespace
        .select { |configuration| configuration&.policy_configuration_valid? }
    end

    def ci_minutes_project_usage
      strong_memoize(:ci_minutes_project_usage) do
        ::Ci::Minutes::ProjectMonthlyUsage.find_or_create_current(project_id: id)
      end
    end

    # Manually preloads saml_providers, which cannot be done in AR, since the
    # relationship is on the root ancestor.
    # This is required since the `:read_group` ability depends on `Group.saml_provider`
    override :project_group_links_with_preload
    def project_group_links_with_preload
      links = super.to_a
      saml_providers = SamlProvider.where(group: links.map { _1.group.root_ancestor }).index_by(&:group_id)
      links.each do |link|
        link.group.root_saml_provider = saml_providers[link.group.root_ancestor.id]
      end

      links
    end

    def github_integration_enabled?
      feature_available?(:github_integration)
    end

    def group_hooks
      GroupHook.where(group_id: group.self_and_ancestors)
    end

    def set_override_pull_mirror_available
      self.pull_mirror_available_overridden = read_attribute(:mirror)
      true
    end

    def set_next_execution_timestamp_to_now
      import_state.set_next_execution_to_now
    end

    def load_licensed_feature_available(feature)
      globally_available = License.feature_available?(feature)

      if ::Gitlab::CurrentSettings.should_check_namespace_plan? && namespace
        globally_available &&
          (open_source_license_granted? || namespace.feature_available_in_plan?(feature))
      else
        globally_available
      end
    end

    def open_source_license_granted?
      public? &&
        namespace.public? &&
        (!::Gitlab.com? || project_setting.legacy_open_source_license_available?)
    end

    def user_defined_rules
      strong_memoize(:user_defined_rules) do
        # Loading the relation in order to memoize it loaded
        regular_or_any_approver_approval_rules.load
      end
    end

    def requirements_ci_variables
      strong_memoize(:requirements_ci_variables) do
        ::Gitlab::Ci::Variables::Collection.new.tap do |variables|
          if requirements.opened.any?
            variables.append(key: 'CI_HAS_OPEN_REQUIREMENTS', value: 'true')
          end
        end
      end
    end

    # Return the group's setting for delayed deletion, false for user namespace projects
    def group_deletion_mode_configured?
      return true if ::Feature.enabled?(:always_perform_delayed_deletion) && !personal?
      return false unless group&.namespace_settings

      group.namespace_settings.delayed_project_removal?
    end

    # If the project is inside a fork network, the mirror URL must
    # also belong to a member of that fork network
    def import_url_inside_fork_network
      if forked?
        mirror_project = ::Project.find_by_url(import_url)

        unless mirror_project.present? && fork_network_projects.include?(mirror_project)
          errors.add(:url, _("must be inside the fork network"))
        end
      end
    end
  end
end
