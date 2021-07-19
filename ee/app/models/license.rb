# frozen_string_literal: true

class License < ApplicationRecord
  include ActionView::Helpers::NumberHelper
  include Gitlab::Utils::StrongMemoize

  STARTER_PLAN = 'starter'
  PREMIUM_PLAN = 'premium'
  ULTIMATE_PLAN = 'ultimate'
  CLOUD_LICENSE_TYPE = 'cloud'
  LICENSE_FILE_TYPE = 'license_file'
  ALLOWED_PERCENTAGE_OF_USERS_OVERAGE = (10 / 100.0)

  EE_ALL_PLANS = [STARTER_PLAN, PREMIUM_PLAN, ULTIMATE_PLAN].freeze

  EES_FEATURES_WITH_USAGE_PING = %i[
    send_emails_from_admin_area
  ].freeze

  EES_FEATURES = %i[
    audit_events
    blocked_issues
    board_iteration_lists
    code_owners
    code_review_analytics
    contribution_analytics
    description_diffs
    elastic_search
    full_codequality_report
    group_activity_analytics
    group_bulk_edit
    group_webhooks
    issuable_default_templates
    issue_weights
    iterations
    ldap_group_sync
    member_lock
    merge_request_approvers
    milestone_charts
    multiple_issue_assignees
    multiple_ldap_servers
    multiple_merge_request_assignees
    multiple_merge_request_reviewers
    project_merge_request_analytics
    protected_refs_for_users
    push_rules
    repository_mirrors
    repository_size_limit
    resource_access_token
    seat_link
    scoped_issue_board
    usage_quotas
    visual_review_app
    wip_limits
  ].freeze + EES_FEATURES_WITH_USAGE_PING

  EEP_FEATURES = EES_FEATURES + %i[
    adjourned_deletion_for_projects_and_groups
    admin_audit_log
    auditor_user
    blocking_merge_requests
    board_assignee_lists
    board_milestone_lists
    ci_cd_projects
    ci_secrets_management
    cluster_agents
    cluster_deployments
    code_owner_approval_required
    commit_committer_check
    compliance_framework
    custom_compliance_frameworks
    cross_project_pipelines
    custom_file_templates
    custom_file_templates_for_namespace
    custom_project_templates
    cycle_analytics_for_groups
    cycle_analytics_for_projects
    db_load_balancing
    default_branch_protection_restriction_in_groups
    default_project_deletion_protection
    disable_name_update_for_users
    email_additional_text
    epics
    extended_audit_events
    external_authorization_service_api_management
    feature_flags_related_issues
    file_locks
    geo
    generic_alert_fingerprinting
    git_two_factor_enforcement
    github_project_service_integration
    group_allowed_email_domains
    group_coverage_reports
    group_forking_protection
    group_ip_restriction
    group_merge_request_analytics
    group_merge_request_approval_settings
    group_milestone_project_releases
    group_project_templates
    group_repository_analytics
    group_saml
    group_saml_group_sync
    group_scoped_ci_variables
    group_wikis
    incident_sla
    incident_metric_upload
    ide_schema_config
    issues_analytics
    jira_issues_integration
    ldap_group_sync_filter
    merge_pipelines
    merge_request_performance_metrics
    admin_merge_request_approvers_rules
    merge_trains
    metrics_reports
    multiple_alert_http_integrations
    multiple_approval_rules
    multiple_group_issue_boards
    multiple_iteration_cadences
    object_storage
    operations_dashboard
    package_forwarding
    pages_size_limit
    productivity_analytics
    project_aliases
    protected_environments
    reject_unsigned_commits
    required_ci_templates
    scoped_labels
    smartcard_auth
    swimlanes
    type_of_work_analytics
    minimal_access_role
    unprotection_restrictions
    ci_project_subscriptions
    incident_timeline_view
    oncall_schedules
    escalation_policies
    export_user_permissions
  ]
  EEP_FEATURES.freeze

  EEU_FEATURES = EEP_FEATURES + %i[
    api_fuzzing
    auto_rollback
    cilium_alerts
    cluster_image_scanning
    external_status_checks
    container_scanning
    coverage_fuzzing
    credentials_inventory
    dast
    dependency_scanning
    devops_adoption
    dora4_analytics
    enforce_personal_access_token_expiration
    enforce_ssh_key_expiration
    enterprise_templates
    environment_alerts
    evaluate_group_level_compliance_pipeline
    group_ci_cd_analytics
    group_level_compliance_dashboard
    group_level_devops_adoption
    incident_management
    inline_codequality
    insights
    instance_level_devops_adoption
    issuable_health_status
    jira_vulnerabilities_integration
    jira_issue_association_enforcement
    license_scanning
    personal_access_token_expiration_policy
    prometheus_alerts
    pseudonymizer
    quality_management
    release_evidence_test_artifacts
    report_approver_rules
    requirements
    sast
    sast_custom_rulesets
    sast_fp_reduction
    secret_detection
    security_dashboard
    security_on_demand_scans
    security_orchestration_policies
    status_page
    subepics
    threat_monitoring
    vulnerability_auto_fix
    vulnerability_finding_signatures
  ]
  EEU_FEATURES.freeze

  FEATURES_BY_PLAN = {
    STARTER_PLAN       => EES_FEATURES,
    PREMIUM_PLAN       => EEP_FEATURES,
    ULTIMATE_PLAN      => EEU_FEATURES
  }.freeze

  PLANS_BY_FEATURE = FEATURES_BY_PLAN.each_with_object({}) do |(plan, features), hash|
    features.each do |feature|
      hash[feature] ||= []
      hash[feature] << plan
    end
  end.freeze

  FEATURES_WITH_USAGE_PING = EES_FEATURES_WITH_USAGE_PING

  # Add on codes that may occur in legacy licenses that don't have a plan yet.
  FEATURES_FOR_ADD_ONS = {
    'GitLab_Auditor_User' => :auditor_user,
    'GitLab_FileLocks' => :file_locks,
    'GitLab_Geo' => :geo
  }.freeze

  # Global features that cannot be restricted to only a subset of projects or namespaces.
  # Use `License.feature_available?(:feature)` to check if these features are available.
  # For all other features, use `project.feature_available?` or `namespace.feature_available?` when possible.
  GLOBAL_FEATURES = %i[
    admin_audit_log
    auditor_user
    custom_file_templates
    custom_project_templates
    db_load_balancing
    default_branch_protection_restriction_in_groups
    elastic_search
    enterprise_templates
    extended_audit_events
    external_authorization_service_api_management
    geo
    ldap_group_sync
    ldap_group_sync_filter
    multiple_ldap_servers
    object_storage
    pages_size_limit
    project_aliases
    repository_size_limit
    required_ci_templates
    seat_link
    usage_quotas
  ].freeze

  ACTIVE_USER_COUNT_THRESHOLD_LEVELS = [
    { range: (2..15), percentage: false, value: 1 },
    { range: (16..25), percentage: false, value: 2 },
    { range: (26..99), percentage: true, value: 10 },
    { range: (100..999), percentage: true, value: 8 },
    { range: (1000..nil), percentage: true, value: 5 }
  ].freeze

  LICENSEE_ATTRIBUTES = %w[Name Email Company].freeze

  validate :valid_license
  validate :check_users_limit, if: :new_record?, unless: [:validate_with_trueup?, :reconciliation_completed?]
  validate :check_trueup, unless: [:persisted?, :reconciliation_completed?], if: :validate_with_trueup?
  validate :check_restricted_user_count, if: :reconciliation_completed?
  validate :not_expired, unless: :persisted?

  before_validation :reset_license, if: :data_changed?

  after_create :update_trial_setting
  after_commit :reset_current
  after_commit :reset_future_dated, on: [:create, :destroy]
  after_commit :reset_previous, on: [:create, :destroy]

  scope :cloud, -> { where(cloud: true) }
  scope :recent, -> { reorder(id: :desc) }
  scope :last_hundred, -> { recent.limit(100) }

  CACHE_KEY = :current_license

  class << self
    def features_for_plan(plan)
      FEATURES_BY_PLAN.fetch(plan, [])
    end

    def plans_with_feature(feature)
      if global_feature?(feature)
        raise ArgumentError, "Use `License.feature_available?` for features that cannot be restricted to only a subset of projects or namespaces"
      end

      PLANS_BY_FEATURE.fetch(feature, [])
    end

    def features_with_usage_ping
      return FEATURES_WITH_USAGE_PING if Gitlab::CurrentSettings.usage_ping_features_enabled?

      []
    end

    def plan_includes_feature?(plan, feature)
      plans_with_feature(feature).include?(plan)
    end

    def current
      cache.fetch(CACHE_KEY, as: License, expires_in: 1.minute) { load_license }
    end

    def cache
      Gitlab::SafeRequestStore[:license_cache] ||=
        Gitlab::JsonCache.new(namespace: :ee, backend: ::Gitlab::ProcessMemoryCache.cache_backend)
    end

    def all_plans
      EE_ALL_PLANS
    end

    delegate :block_changes?, :feature_available?, to: :current, allow_nil: true

    def reset_current
      cache.expire(CACHE_KEY)
    end

    def load_license
      return unless self.table_exists?

      self.last_hundred.find { |license| license.valid? && license.started? }
    end

    def future_dated
      Gitlab::SafeRequestStore.fetch(:future_dated_license) { load_future_dated }
    end

    def reset_future_dated
      Gitlab::SafeRequestStore.delete(:future_dated_license)
    end

    def previous
      Gitlab::SafeRequestStore.fetch(:previous_license) { load_previous }
    end

    def reset_previous
      Gitlab::SafeRequestStore.delete(:previous_license)
    end

    def global_feature?(feature)
      GLOBAL_FEATURES.include?(feature)
    end

    def eligible_for_trial?
      Gitlab::CurrentSettings.license_trial_ends_on.nil?
    end

    def trial_ends_on
      Gitlab::CurrentSettings.license_trial_ends_on
    end

    def history
      decryptable_licenses = all.select { |license| license.license.present? }
      decryptable_licenses.sort_by { |license| [license.starts_at, license.created_at, license.expires_at] }.reverse
    end

    def with_valid_license
      current_license = License.current

      return unless current_license
      return if current_license.trial?

      yield(current_license) if block_given?
    end

    def current_cloud_license?(key)
      current_license = License.current
      return false unless current_license&.cloud_license?

      current_license.data == key
    end

    private

    def load_future_dated
      self.last_hundred.find { |license| license.valid? && license.future_dated? }
    end

    def load_previous
      self.last_hundred.find { |license| license.valid? && !license.future_dated? && license != License.current }
    end
  end

  def data_filename
    company_name = self.licensee_company || self.licensee.each_value.first
    clean_company_name = company_name.gsub(/[^A-Za-z0-9]/, "")
    "#{clean_company_name}.gitlab-license"
  end

  def data_file=(file)
    self.data = file.read
  end

  def md5
    normalized_data = self.data.gsub("\r\n", "\n").gsub(/\n+$/, '') + "\n"

    Digest::MD5.hexdigest(normalized_data)
  end

  def license
    return unless self.data

    @license ||=
      begin
        Gitlab::License.import(self.data)
      rescue Gitlab::License::ImportError
        nil
      end
  end

  def license?
    self.license && self.license.valid?
  end

  def method_missing(method_name, *arguments, &block)
    if License.column_names.include?(method_name.to_s)
      super
    elsif license && license.respond_to?(method_name)
      license.__send__(method_name, *arguments, &block) # rubocop:disable GitlabSecurity/PublicSend
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    if License.column_names.include?(method_name.to_s)
      super
    elsif license && license.respond_to?(method_name)
      true
    else
      super
    end
  end

  # New licenses persists only the `plan` (premium, starter, ..). But, old licenses
  # keep `add_ons`.
  def add_ons
    restricted_attr(:add_ons, {})
  end

  # License zuora_subscription_id
  def subscription_id
    restricted_attr(:subscription_id)
  end

  def reconciliation_completed?
    restricted_attr(:reconciliation_completed)
  end

  def features_from_add_ons
    add_ons.map { |name, count| FEATURES_FOR_ADD_ONS[name] if count.to_i > 0 }.compact
  end

  def features
    @features ||= (self.class.features_for_plan(plan) + features_from_add_ons).to_set
  end

  def feature_available?(feature)
    return false if trial? && expired?

    features.include?(feature)
  end

  def license_id
    restricted_attr(:id)
  end

  def restricted_user_count
    restricted_attr(:active_user_count)
  end

  def restricted_user_count?
    restricted_user_count.to_i > 0
  end

  def previous_user_count
    restricted_attr(:previous_user_count)
  end

  def plan
    restricted_attr(:plan).presence || STARTER_PLAN
  end

  def edition
    case restricted_attr(:plan)
    when 'ultimate'
      'EEU'
    when 'premium'
      'EEP'
    when 'starter'
      'EES'
    else # Older licenses
      'EE'
    end
  end

  def daily_billable_users_count
    strong_memoize(:daily_billable_users_count) do
      ::Analytics::UsageTrends::Measurement.find_latest_or_fallback(:billable_users).count
    end
  end

  def validate_with_trueup?
    [restricted_attr(:trueup_quantity),
     restricted_attr(:trueup_from),
     restricted_attr(:trueup_to)].all?(&:present?)
  end

  def trial?
    restricted_attr(:trial)
  end

  def ultimate?
    plan == License::ULTIMATE_PLAN
  end

  alias_method :exclude_guests_from_active_count?, :ultimate?

  def remaining_days
    return 0 if expired?

    (expires_at - Date.today).to_i
  end

  def overage(user_count = nil)
    return 0 if restricted_user_count.nil?

    user_count ||= daily_billable_users_count

    [user_count - restricted_user_count, 0].max
  end

  def overage_with_historical_max
    overage(maximum_user_count)
  end

  def historical_data(from: nil, to: nil)
    from ||= starts_at_for_historical_data
    to ||= expires_at_for_historical_data

    HistoricalData.during(from..to)
  end

  def historical_max(from: nil, to: nil)
    from ||= starts_at_for_historical_data
    to ||= expires_at_for_historical_data

    HistoricalData.max_historical_user_count(from: from, to: to)
  end

  def maximum_user_count
    [historical_max(from: starts_at), daily_billable_users_count].max
  end

  def update_trial_setting
    return unless license.restrictions[:trial]
    return if license.expires_at.nil?

    settings = ApplicationSetting.current
    return if settings.nil?
    return if settings.license_trial_ends_on.present?

    settings.update license_trial_ends_on: license.expires_at
  end

  def paid?
    [License::STARTER_PLAN, License::PREMIUM_PLAN, License::ULTIMATE_PLAN].include?(plan)
  end

  def started?
    starts_at <= Date.current
  end

  def future_dated?
    starts_at > Date.current
  end

  def cloud_license?
    !!license&.cloud_licensing?
  end

  def customer_service_enabled?
    !!license&.operational_metrics?
  end

  def license_type
    cloud_license? ? CLOUD_LICENSE_TYPE : LICENSE_FILE_TYPE
  end

  def auto_renew
    false
  end

  def active_user_count_threshold
    ACTIVE_USER_COUNT_THRESHOLD_LEVELS.find do |threshold|
      threshold[:range].include?(restricted_user_count)
    end
  end

  def active_user_count_threshold_reached?
    return false if restricted_user_count.nil?
    return false if daily_billable_users_count <= 1
    return false if daily_billable_users_count > restricted_user_count

    active_user_count_threshold[:value] >= if active_user_count_threshold[:percentage]
                                             remaining_user_count.fdiv(daily_billable_users_count) * 100
                                           else
                                             remaining_user_count
                                           end
  end

  def remaining_user_count
    restricted_user_count - daily_billable_users_count
  end

  LICENSEE_ATTRIBUTES.each do |attribute|
    define_method "licensee_#{attribute.downcase}" do
      licensee[attribute]
    end
  end

  def activated_at
    super || created_at
  end

  private

  def restricted_attr(name, default = nil)
    return default unless license? && restricted?(name)

    restrictions[name]
  end

  def reset_current
    self.class.reset_current
  end

  def reset_future_dated
    self.class.reset_future_dated
  end

  def reset_previous
    self.class.reset_previous
  end

  def reset_license
    @license = nil
  end

  def valid_license
    return if license?

    self.errors.add(:base, _('The license key is invalid. Make sure it is exactly as you received it from GitLab Inc.'))
  end

  def prior_historical_max
    @prior_historical_max ||= begin
      historical_max(from: previous_started_at, to: previous_expired_at)
    end
  end

  def restricted_user_count_with_threshold
    # overage should only be applied for new subscriptions not for renewals.
    return restricted_user_count if previous_user_count

    (restricted_user_count * (1 + ALLOWED_PERCENTAGE_OF_USERS_OVERAGE)).to_i
  end

  def check_users_limit
    return if cloud_license?
    return unless restricted_user_count

    if previous_user_count && (prior_historical_max <= previous_user_count)
      return if restricted_user_count >= daily_billable_users_count
    else
      return if restricted_user_count_with_threshold >= prior_historical_max
    end

    user_count = prior_historical_max == 0 ? daily_billable_users_count : prior_historical_max

    add_limit_error(current_period: prior_historical_max == 0, user_count: user_count)
  end

  def check_trueup
    trueup_qty          = restrictions[:trueup_quantity]
    trueup_from         = Date.parse(restrictions[:trueup_from]).beginning_of_day rescue previous_started_at
    trueup_to           = Date.parse(restrictions[:trueup_to]).end_of_day rescue previous_expired_at
    max_historical      = historical_max(from: trueup_from, to: trueup_to)
    expected_trueup_qty = if previous_user_count
                            max_historical - previous_user_count
                          else
                            max_historical - daily_billable_users_count
                          end

    if trueup_qty >= expected_trueup_qty
      check_restricted_user_count
    else
      message = ["You have applied a True-up for #{trueup_qty} #{"user".pluralize(trueup_qty)}"]
      message << "but you need one for #{expected_trueup_qty} #{"user".pluralize(expected_trueup_qty)}."
      message << "Please contact sales at https://about.gitlab.com/sales/"

      self.errors.add(:base, message.join(' '))
    end
  end

  def check_restricted_user_count
    return unless restricted_user_count && restricted_user_count < daily_billable_users_count

    add_limit_error(user_count: daily_billable_users_count)
  end

  def add_limit_error(current_period: true, user_count:)
    overage_count = overage(user_count)

    message =  [current_period ? "This GitLab installation currently has" : "During the year before this license started, this GitLab installation had"]
    message << "#{number_with_delimiter(user_count)} active #{"user".pluralize(user_count)},"
    message << "exceeding this license's limit of #{number_with_delimiter(restricted_user_count)} by"
    message << "#{number_with_delimiter(overage_count)} #{"user".pluralize(overage_count)}."
    message << "Please upload a license for at least"
    message << "#{number_with_delimiter(user_count)} #{"user".pluralize(user_count)} or contact sales at https://about.gitlab.com/sales/"

    self.errors.add(:base, message.join(' '))
  end

  def not_expired
    return unless self.license? && self.expired?

    self.errors.add(:base, _('This license has already expired.'))
  end

  def previous_started_at
    (License.previous&.starts_at || starts_at - 1.year).beginning_of_day
  end

  def previous_expired_at
    (License.previous&.expires_at || starts_at).end_of_day
  end

  def starts_at_for_historical_data
    (starts_at || Time.current - 1.year).beginning_of_day
  end

  def expires_at_for_historical_data
    (expires_at || Time.current).end_of_day
  end
end
