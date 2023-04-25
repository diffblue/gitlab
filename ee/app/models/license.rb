# frozen_string_literal: true

# License is the artifact of purchasing a GitLab subscription for self-managed
# and it is installed at instance level.
# GitLab SaaS is a special self-managed instance which has a license installed
# that is mapped to an Ultimate plan.
class License < MainClusterwide::ApplicationRecord
  include ActionView::Helpers::NumberHelper
  include Gitlab::Utils::StrongMemoize

  STARTER_PLAN = 'starter'
  PREMIUM_PLAN = 'premium'
  ULTIMATE_PLAN = 'ultimate'
  ONLINE_CLOUD_TYPE = 'online_cloud'
  OFFLINE_CLOUD_TYPE = 'offline_cloud'
  LEGACY_LICENSE_TYPE = 'legacy_license'
  ALLOWED_PERCENTAGE_OF_USERS_OVERAGE = (10 / 100.0)

  NOTIFICATION_DAYS_BEFORE_TRIAL_EXPIRY = 1.week
  ADMIN_NOTIFICATION_DAYS_BEFORE_EXPIRY = 15.days

  EE_ALL_PLANS = [STARTER_PLAN, PREMIUM_PLAN, ULTIMATE_PLAN].freeze

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
  validate :check_trueup, unless: :reconciliation_completed?, if: [:new_record?, :validate_with_trueup?]
  validate :check_restricted_user_count, if: [:new_record?, :reconciliation_completed?]
  validate :not_expired, if: :new_record?

  before_validation :reset_license, if: :data_changed?

  after_create :update_trial_setting
  after_commit :reset_current
  after_commit :reset_future_dated, on: [:create, :destroy]

  scope :cloud, -> { where(cloud: true) }
  scope :recent, -> { reorder(id: :desc) }
  scope :last_hundred, -> { recent.limit(100) }

  CACHE_KEY = :current_license

  class << self
    def current
      cache.fetch(CACHE_KEY, as: License, expires_in: 1.minute) { load_license }
    end

    def reset_current
      cache.expire(CACHE_KEY)
    end

    def cache
      Gitlab::SafeRequestStore[:license_cache] ||=
        Gitlab::JsonCache.new(namespace: :ee, backend: ::Gitlab::ProcessMemoryCache.cache_backend, cache_key_strategy: :version)
    end

    def all_plans
      EE_ALL_PLANS
    end

    def block_changes?
      !!current&.block_changes?
    end

    def feature_available?(feature)
      !!current&.feature_available?(feature)
    end

    def load_license
      return unless self.table_exists?

      last_hundred = self.last_hundred
      last_hundred.find { |license| license.valid? && license.started? && !license.expired? } ||
        last_hundred.find { |license| license.valid? && license.started? }
    end

    def future_dated
      Gitlab::SafeRequestStore.fetch(:future_dated_license) { load_future_dated }
    end

    def reset_future_dated
      Gitlab::SafeRequestStore.delete(:future_dated_license)
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
  end

  def offline_cloud_license?
    cloud_license? && !!license&.offline_cloud_licensing?
  end

  def restricted_user_count
    restricted_attr(:active_user_count)
  end

  def restricted_user_count?
    restricted_user_count.to_i > 0
  end

  def ultimate?
    plan == License::ULTIMATE_PLAN
  end

  def customer_service_enabled?
    !!license&.operational_metrics?
  end

  def trial?
    restricted_attr(:trial)
  end

  def data_filename
    company_name = self.licensee_company || self.licensee.each_value.first
    clean_company_name = company_name.gsub(/[^A-Za-z0-9]/, "")
    "#{clean_company_name}.gitlab-license"
  end

  def data_file=(file)
    self.data = file.read
  end

  def normalized_data
    data.gsub("\r\n", "\n").gsub(/\n+$/, '') + "\n"
  end

  def md5
    return if Gitlab::FIPS.enabled?

    Digest::MD5.hexdigest(normalized_data)
  end

  def sha256
    Digest::SHA256.hexdigest(normalized_data)
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

  def features
    @features ||= GitlabSubscriptions::Features.features(plan: plan, add_ons: add_ons)
  end

  def feature_available?(feature)
    return false if trial? && expired?

    features.include?(feature)
  end

  def license_id
    restricted_attr(:id)
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
    daily_billable_users.count
  end

  def daily_billable_users_updated_time
    (daily_billable_users.try(:recorded_at) || Time.zone.now).to_s
  end

  def validate_with_trueup?
    return false if converting_from_legacy_to_cloud?

    [restricted_attr(:trueup_quantity),
     restricted_attr(:trueup_from),
     restricted_attr(:trueup_to)].all?(&:present?)
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

  def online_cloud_license?
    cloud_license? && !license&.offline_cloud_licensing?
  end

  def current?
    self == License.current
  end

  def license_type
    return OFFLINE_CLOUD_TYPE if offline_cloud_license?
    return ONLINE_CLOUD_TYPE if online_cloud_license?

    LEGACY_LICENSE_TYPE
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

  # Overrides method from Gitlab::License which will be removed in a future version
  def notify_admins?
    return false if expires_at.blank?
    return true if expired?

    notification_days = trial? ? NOTIFICATION_DAYS_BEFORE_TRIAL_EXPIRY : ADMIN_NOTIFICATION_DAYS_BEFORE_EXPIRY

    Date.current >= (expires_at - notification_days)
  end

  # Overrides method from Gitlab::License which will be removed in a future version
  def notify_users?
    return false if expires_at.blank?

    notification_start_date = trial? ? expires_at - NOTIFICATION_DAYS_BEFORE_TRIAL_EXPIRY : block_changes_at

    Date.current >= notification_start_date
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

  def reset_license
    @license = nil
  end

  def valid_license
    return if license?

    error_message = if online_cloud_license?
                      _('The license key is invalid.')
                    else
                      _('The license key is invalid. Make sure it is exactly as you received it from GitLab Inc.')
                    end

    self.errors.add(:base, error_message)
  end

  # This method, `previous_started_at` and `previous_expired_at` are
  # only used in the validation methods `check_users_limit` and check_trueup
  # which are only used when uploading/creating a new license.
  # The method will not work in other workflows since it has a dependency to
  # use the current license as the previous in the system.
  def prior_historical_max
    strong_memoize(:prior_historical_max) do
      historical_max(from: previous_started_at, to: previous_expired_at)
    end
  end

  # See comment for `prior_historical_max`.
  def previous_started_at
    (License.current&.starts_at || starts_at - 1.year).beginning_of_day
  end

  # See comment for `prior_historical_max`.
  def previous_expired_at
    (License.current&.expires_at || expires_at && expires_at - 1.year || starts_at).end_of_day
  end

  def restricted_user_count_with_threshold
    (restricted_user_count * (1 + ALLOWED_PERCENTAGE_OF_USERS_OVERAGE)).to_i
  end

  def check_users_limit
    return if cloud_license?
    return unless restricted_user_count

    user_count = daily_billable_users_count
    current_period = true

    if previous_user_count && (prior_historical_max <= previous_user_count)
      return if restricted_user_count_with_threshold >= daily_billable_users_count
    else
      return if restricted_user_count_with_threshold >= prior_historical_max

      user_count = prior_historical_max
      current_period = false
    end

    add_limit_error(current_period: current_period, user_count: user_count)
  end

  def trueup_from
    Date.parse(restrictions[:trueup_from]).beginning_of_day
  rescue StandardError
    previous_started_at
  end

  def trueup_to
    Date.parse(restrictions[:trueup_to]).end_of_day
  rescue StandardError
    previous_expired_at
  end

  def converting_from_legacy_to_cloud?
    return false unless new_record? && cloud?

    license = License.current
    license&.license_type == LEGACY_LICENSE_TYPE && license&.subscription_id == subscription_id
  end

  def check_trueup
    unless previous_user_count
      check_restricted_user_count
      return
    end

    trueup_qty = restrictions[:trueup_quantity]
    max_historical = historical_max(from: trueup_from, to: trueup_to)
    expected_trueup_qty = max_historical - previous_user_count

    if trueup_quantity_with_threshold >= expected_trueup_qty
      check_restricted_user_count
    else
      message = ["You have applied a True-up for #{trueup_qty} #{"user".pluralize(trueup_qty)}"]
      message << "but you need one for #{expected_trueup_qty} #{"user".pluralize(expected_trueup_qty)}."
      message << "Please contact sales at https://about.gitlab.com/sales/"

      self.errors.add(:base, :check_trueup, message: message.join(' '))
    end
  end

  def trueup_quantity_with_threshold
    (restrictions[:trueup_quantity] * (1 + ALLOWED_PERCENTAGE_OF_USERS_OVERAGE)).to_i
  end

  def check_restricted_user_count
    return if cloud_license?
    return unless restricted_user_count && restricted_user_count_with_threshold < daily_billable_users_count

    add_limit_error(type: :check_restricted_user_count, user_count: daily_billable_users_count)
  end

  def add_limit_error(user_count:, current_period: true, type: :invalid)
    overage_count = overage(user_count)

    message =  [current_period ? "This GitLab installation currently has" : "During the year before this license started, this GitLab installation had"]
    message << "#{number_with_delimiter(user_count)} active #{"user".pluralize(user_count)},"
    message << "exceeding this license's limit of #{number_with_delimiter(restricted_user_count)} by"
    message << "#{number_with_delimiter(overage_count)} #{"user".pluralize(overage_count)}."
    message << "Please add a license for at least"
    message << "#{number_with_delimiter(user_count)} #{"user".pluralize(user_count)} or contact sales at https://about.gitlab.com/sales/"

    self.errors.add(:base, type, message: message.join(' '))
  end

  def not_expired
    return unless self.license? && self.expired?

    self.errors.add(:base, _('This license has already expired.'))
  end

  def starts_at_for_historical_data
    (starts_at || Time.current - 1.year).beginning_of_day
  end

  def expires_at_for_historical_data
    (expires_at || Time.current).end_of_day
  end

  def daily_billable_users
    strong_memoize(:daily_billable_users) do
      ::Analytics::UsageTrends::Measurement.find_latest_or_fallback(:billable_users)
    end
  end
end

License.prepend_mod
