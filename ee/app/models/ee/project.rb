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
    include IgnorableColumns

    GIT_LFS_DOWNLOAD_OPERATION = 'download'
    PUBLIC_COST_FACTOR_RELEASE_DAY = Date.new(2021, 7, 17).freeze

    prepended do
      include Elastic::ProjectsSearch
      include EachBatch
      include InsightsFeature
      include DeprecatedApprovalsBeforeMerge
      include UsageStatistics
      include ProjectSecurityScannersInformation

      ignore_columns :mirror_last_update_at, :mirror_last_successful_update_at, remove_after: '2019-12-15', remove_with: '12.6'
      ignore_columns :pull_mirror_branch_prefix, remove_after: '2021-02-22', remove_with: '14.0'

      before_save :set_override_pull_mirror_available, unless: -> { ::Gitlab::CurrentSettings.mirror_available }
      before_save :set_next_execution_timestamp_to_now, if: ->(project) { project.mirror? && project.mirror_changed? && project.import_state }

      after_create :create_security_setting, unless: :security_setting

      belongs_to :mirror_user, class_name: 'User'
      belongs_to :deleting_user, foreign_key: 'marked_for_deletion_by_user_id', class_name: 'User'

      has_one :repository_state, class_name: 'ProjectRepositoryState', inverse_of: :project
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
      has_many :approval_rules, class_name: 'ApprovalProjectRule' do
        def applicable_to_branch(branch)
          includes(:protected_branches).select { |rule| rule.applies_to_branch?(branch) }
        end

        def inapplicable_to_branch(branch)
          includes(:protected_branches).reject { |rule| rule.applies_to_branch?(branch) }
        end
      end
      has_many :external_status_checks, class_name: 'MergeRequests::ExternalStatusCheck'
      has_many :approval_merge_request_rules, through: :merge_requests, source: :approval_rules
      has_many :audit_events, as: :entity
      has_many :path_locks
      has_many :requirements, inverse_of: :project, class_name: 'RequirementsManagement::Requirement'
      has_many :dast_scanner_profiles

      # the rationale behind vulnerabilities and vulnerability_findings can be found here:
      # https://gitlab.com/gitlab-org/gitlab/issues/10252#terminology
      has_many :vulnerabilities
      has_many :vulnerability_feedback, class_name: 'Vulnerabilities::Feedback'
      has_many :vulnerability_historical_statistics, class_name: 'Vulnerabilities::HistoricalStatistic'
      has_many :vulnerability_findings, class_name: 'Vulnerabilities::Finding', inverse_of: :project do
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

      has_many :protected_environments
      has_many :software_license_policies, inverse_of: :project, class_name: 'SoftwareLicensePolicy'
      has_many :software_licenses, through: :software_license_policies
      accepts_nested_attributes_for :software_license_policies, allow_destroy: true
      has_many :merge_trains, foreign_key: 'target_project_id', inverse_of: :target_project

      has_many :project_aliases

      has_many :upstream_project_subscriptions, class_name: 'Ci::Subscriptions::Project', foreign_key: :downstream_project_id, inverse_of: :downstream_project
      has_many :upstream_projects, class_name: 'Project', through: :upstream_project_subscriptions, source: :upstream_project
      has_many :downstream_project_subscriptions, class_name: 'Ci::Subscriptions::Project', foreign_key: :upstream_project_id, inverse_of: :upstream_project
      has_many :downstream_projects, class_name: 'Project', through: :downstream_project_subscriptions, source: :downstream_project

      has_many :sourced_pipelines, class_name: 'Ci::Sources::Project', foreign_key: :source_project_id

      has_many :incident_management_oncall_schedules, class_name: 'IncidentManagement::OncallSchedule', inverse_of: :project
      has_many :incident_management_oncall_rotations, class_name: 'IncidentManagement::OncallRotation', through: :incident_management_oncall_schedules, source: :rotations
      has_many :incident_management_escalation_policies, class_name: 'IncidentManagement::EscalationPolicy', inverse_of: :project

      has_one :security_orchestration_policy_configuration, class_name: 'Security::OrchestrationPolicyConfiguration', foreign_key: :project_id, inverse_of: :project

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

      scope :with_code_coverage, -> do
        joins(:daily_build_group_report_results).merge(::Ci::DailyBuildGroupReportResult.with_coverage.with_default_branch).group(:id)
      end

      scope :including_project, ->(project) { where(id: project) }
      scope :with_wiki_enabled, -> { with_feature_enabled(:wiki) }
      scope :within_shards, -> (shard_names) { where(repository_storage: Array(shard_names)) }
      scope :verification_failed_repos, -> { joins(:repository_state).merge(ProjectRepositoryState.verification_failed_repos) }
      scope :verification_failed_wikis, -> { joins(:repository_state).merge(ProjectRepositoryState.verification_failed_wikis) }
      scope :for_plan_name, -> (name) { joins(namespace: { gitlab_subscription: :hosted_plan }).where(plans: { name: name }) }
      scope :requiring_code_owner_approval,
            -> { joins(:protected_branches).where(protected_branches: { code_owner_approval_required: true }) }
      scope :github_imported, -> { where(import_type: 'github') }
      scope :with_protected_branches, -> { joins(:protected_branches) }
      scope :with_repositories_enabled, -> { joins(:project_feature).where(project_features: { repository_access_level: ::ProjectFeature::ENABLED }) }

      scope :with_security_reports_stored, -> { where('EXISTS (?)', ::Vulnerabilities::Finding.scoped_project.select(1)) }
      scope :with_security_reports, -> { where('EXISTS (?)', ::Ci::JobArtifact.security_reports.scoped_project.select(1)) }
      scope :with_github_integration_pipeline_events, -> { joins(:github_integration).merge(::Integrations::Github.pipeline_hooks) }
      scope :with_active_prometheus_integration, -> { joins(:prometheus_integration).merge(::Integrations::Prometheus.active) }
      scope :with_enabled_incident_sla, -> { joins(:incident_management_setting).where(project_incident_management_settings: { sla_timer: true }) }
      scope :mirrored_with_enabled_pipelines, -> do
        joins(:project_feature).mirror.where(mirror_trigger_builds: true,
                                             project_features: { builds_access_level: ::ProjectFeature::ENABLED })
      end
      scope :with_slack_integration, -> { joins(:slack_integration) }
      scope :with_slack_slash_commands_integration, -> { joins(:slack_slash_commands_integration) }
      scope :with_prometheus_integration, -> { joins(:prometheus_integration) }
      scope :aimed_for_deletion, -> (date) { where('marked_for_deletion_at <= ?', date).without_deleted }
      scope :not_aimed_for_deletion, -> { where(marked_for_deletion_at: nil) }
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

      scope :order_by_total_repository_size_excess_desc, -> (limit) do
        excess_arel = ::ProjectStatistics.arel_table[:repository_size] +
                   ::ProjectStatistics.arel_table[:lfs_objects_size] -
                   arel_table.coalesce(arel_table[:repository_size_limit], limit, 0)
        alias_node = Arel::Nodes::SqlLiteral.new('excess_storage')

        select(*arel.projections, excess_arel.as(alias_node))
          .joins(:statistics)
          .order(excess_arel.desc)
      end

      delegate :shared_runners_minutes, :shared_runners_seconds, :shared_runners_seconds_last_reset,
        to: :statistics, allow_nil: true

      delegate :ci_minutes_quota, to: :shared_runners_limit_namespace

      delegate :merge_pipelines_enabled, :merge_pipelines_enabled=, to: :ci_cd_settings, allow_nil: true
      delegate :merge_trains_enabled, :merge_trains_enabled=, to: :ci_cd_settings, allow_nil: true

      delegate :auto_rollback_enabled, :auto_rollback_enabled=, to: :ci_cd_settings, allow_nil: true
      delegate :closest_gitlab_subscription, to: :namespace

      delegate :requirements_access_level, to: :project_feature, allow_nil: true
      delegate :pipeline_configuration_full_path, to: :compliance_management_framework, allow_nil: true
      alias_attribute :compliance_pipeline_configuration_full_path, :pipeline_configuration_full_path

      delegate :prevent_merge_without_jira_issue, to: :project_setting

      validates :repository_size_limit,
        numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }
      validates :max_pages_size,
        numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true,
                        less_than: ::Gitlab::Pages::MAX_SIZE / 1.megabyte }

      validates :approvals_before_merge, numericality: true, allow_blank: true
      validate :import_url_inside_fork_network, if: :import_url_changed?

      with_options if: :mirror? do
        validates :import_url, presence: true
        validates :mirror_user, presence: true
      end

      # Because we use default_value_for we need to be sure
      # requirements_enabled= method does exist even if we rollback migration.
      # Otherwise many tests from spec/migrations will fail.
      def requirements_enabled=(value)
        if has_attribute?(:requirements_enabled)
          write_attribute(:requirements_enabled, value)
        end
      end

      default_value_for :requirements_enabled, true

      accepts_nested_attributes_for :status_page_setting, update_only: true, allow_destroy: true
      accepts_nested_attributes_for :compliance_framework_setting, update_only: true, allow_destroy: true

      alias_attribute :fallback_approvals_required, :approvals_before_merge

      def jira_issue_association_required_to_merge_enabled?
        strong_memoize(:jira_issue_association_required_to_merge_enabled) do
          next false unless jira_issues_integration_available?
          next false unless jira_integration&.active?
          next false unless ::Feature.enabled?(:jira_issue_association_on_merge_request, self, default_enabled: :yaml)
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
    end

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
        joins(<<~SQL)
          LEFT JOIN #{::Integration.table_name} ON #{::Integration.table_name}.project_id = projects.id
            AND #{::Integration.table_name}.type = 'GitlabSlackApplicationService'
            AND #{::Integration.table_name}.active IS true
        SQL
          .where(integrations: { id: nil })
      end

      override :with_web_entity_associations
      def with_web_entity_associations
        super.preload(:compliance_framework_setting, group: [:ip_restrictions, :saml_provider])
      end

      override :with_api_entity_associations
      def with_api_entity_associations
        super.preload(group: [:ip_restrictions, :saml_provider])
      end
    end

    def can_store_security_reports?
      namespace.store_security_reports_available? || public?
    end

    # The `only_successful` flag is wrong here and will be addressed by
    # https://gitlab.com/gitlab-org/gitlab/-/issues/331950
    # We will also remove the fallback to `latest_not_ingested_security_pipeline` method with that issue.
    def latest_pipeline_with_security_reports(only_successful: false)
      (!only_successful && latest_ingested_security_pipeline) || latest_not_ingested_security_pipeline(only_successful)
    end

    def latest_pipeline_with_reports(reports)
      all_pipelines.success.newest_first(ref: default_branch).with_reports(reports).take
    end

    def security_reports_up_to_date_for_ref?(ref)
      latest_pipeline_with_security_reports(only_successful: true) == ci_pipelines.newest_first(ref: ref).take
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
      super && !ci_minutes_quota.minutes_used_up?
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

    def push_audit_events_enabled?
      ::Feature.enabled?(:repository_push_audit_event, self)
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
        feature_available?(:github_project_service_integration)
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
      return unless group && feature_available?(:group_webhooks)

      group_hooks.hooks_for(hooks_scope).any?
    end

    def execute_external_compliance_hooks(data)
      external_status_checks.each do |approval_rule|
        approval_rule.async_execute(data)
      end
    end

    def execute_hooks(data, hooks_scope = :push_hooks)
      super

      if group && feature_available?(:group_webhooks)
        run_after_commit_or_now do
          group_hooks.hooks_for(hooks_scope).each do |hook|
            hook.async_execute(data, hooks_scope.to_s)
          end
        end
      end
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
      super && !(group && ::Gitlab::CurrentSettings.lock_memberships_to_ldap?)
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
          h[key] = visible_user_defined_rules(branch: key) + approval_rules.report_approver
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
      super && feature_available?(:merge_request_approvers)
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
      super && password_authentication_enabled_for_web?
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
        ::Gitlab::RepositorySizeChecker.new(
          current_size_proc: -> { statistics.total_repository_size },
          limit: actual_size_limit,
          namespace: namespace,
          enabled: License.feature_available?(:repository_size_limit)
        )
      end
    end

    def repository_size_excess
      return 0 unless actual_size_limit.to_i > 0

      [statistics.total_repository_size - actual_size_limit, 0].max
    end

    def username_only_import_url=(value)
      unless ::Gitlab::UrlSanitizer.valid?(value)
        self.import_url = value
        self.import_data&.user = nil
        value
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

    def merge_requests_ff_only_enabled
      super
    end
    alias_method :merge_requests_ff_only_enabled?, :merge_requests_ff_only_enabled

    override :disabled_integrations
    def disabled_integrations
      strong_memoize(:disabled_integrations) do
        gh = github_integration_enabled? ? [] : %w[github]
        slack = ::Gitlab::CurrentSettings.slack_app_enabled ? %w[slack_slash_commands] : %w[gitlab_slack_application]

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
        License.global_feature?(feature) || licensed_feature_available?(feature)
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

    def log_geo_updated_events
      repository.log_geo_updated_event
      wiki.repository.log_geo_updated_event
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
        ::Gitlab::CurrentSettings.deletion_adjourned_period > 0 &&
        group_deletion_mode_configured?
    end

    def marked_for_deletion?
      marked_for_deletion_at.present? &&
        feature_available?(:adjourned_deletion_for_projects_and_groups)
    end

    def ancestor_marked_for_deletion
      return unless feature_available?(:adjourned_deletion_for_projects_and_groups)

      ancestors(hierarchy_order: :asc)
        .joins(:deletion_schedule).first
    end

    def disable_overriding_approvers_per_merge_request
      strong_memoize(:disable_overriding_approvers_per_merge_request) do
        next super unless License.feature_available?(:admin_merge_request_approvers_rules)

        ::Gitlab::CurrentSettings.disable_overriding_approvers_per_merge_request? || super
      end
    end

    def disable_overriding_approvers_per_merge_request?
      !!disable_overriding_approvers_per_merge_request
    end

    def merge_requests_author_approval
      strong_memoize(:merge_requests_author_approval) do
        next super unless License.feature_available?(:admin_merge_request_approvers_rules)
        next false if ::Gitlab::CurrentSettings.prevent_merge_requests_author_approval?

        super
      end
    end

    def merge_requests_author_approval?
      !!merge_requests_author_approval
    end

    def merge_requests_disable_committers_approval
      strong_memoize(:merge_requests_disable_committers_approval) do
        next super unless License.feature_available?(:admin_merge_request_approvers_rules)

        ::Gitlab::CurrentSettings.prevent_merge_requests_committers_approval? || super
      end
    end

    def merge_requests_disable_committers_approval?
      !!merge_requests_disable_committers_approval
    end

    def license_compliance(pipeline = latest_pipeline_with_reports(::Ci::JobArtifact.license_scanning_reports))
      SCA::LicenseCompliance.new(self, pipeline)
    end

    override :template_source?
    def template_source?
      return true if namespace_id == ::Gitlab::CurrentSettings.current_application_settings.custom_project_templates_group_id

      ::Project.with_groups_level_repos_templates.exists?(id)
    end

    override :predefined_variables
    def predefined_variables
      super.concat(requirements_ci_variables)
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

    def force_cost_factor?
      ::Gitlab.com? && public? &&
        ::Feature.enabled?(:ci_minutes_public_project_cost_factor, self, default_enabled: :yaml) &&
        namespace.created_at >= PUBLIC_COST_FACTOR_RELEASE_DAY
    end

    private

    def github_integration_enabled?
      feature_available?(:github_project_service_integration)
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
          (public? && namespace.public? || namespace.feature_available_in_plan?(feature))
      else
        globally_available
      end
    end

    def user_defined_rules
      strong_memoize(:user_defined_rules) do
        # Loading the relation in order to memoize it loaded
        approval_rules.regular_or_any_approver.order(rule_type: :desc, id: :asc).load
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
      group && group.namespace_settings.delayed_project_removal?
    end

    def latest_ingested_security_pipeline
      vulnerability_statistic&.pipeline
    end

    def latest_not_ingested_security_pipeline(only_successful)
      pipeline_scope = all_pipelines.newest_first(ref: default_branch)
      pipeline_scope = pipeline_scope.success if only_successful

      pipeline_scope.with_reports(::Ci::JobArtifact.security_reports).first ||
        pipeline_scope.with_legacy_security_reports.first
    end

    # If the project is inside a fork network, the mirror URL must
    # also belong to a member of that fork network
    def import_url_inside_fork_network
      return unless ::Feature.enabled?(:block_external_fork_network_mirrors, self, default_enabled: :yaml)

      if forked?
        mirror_project = ::Project.find_by_url(import_url)

        unless mirror_project.present? && fork_network_projects.include?(mirror_project)
          errors.add(:url, _("must be inside the fork network"))
        end
      end
    end
  end
end
