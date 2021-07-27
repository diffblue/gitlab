# frozen_string_literal: true

class GitlabSubscription < ApplicationRecord
  include EachBatch
  include Gitlab::Utils::StrongMemoize

  EOA_ROLLOUT_DATE = '2021-01-26'

  enum trial_extension_type: { extended: 1, reactivated: 2 }

  default_value_for(:start_date) { Date.today }
  before_update :log_previous_state_for_update
  after_commit :index_namespace, on: [:create, :update]
  after_destroy_commit :log_previous_state_for_destroy

  belongs_to :namespace
  belongs_to :hosted_plan, class_name: 'Plan'

  validates :seats, :start_date, presence: true
  validates :namespace_id, uniqueness: true, presence: true

  delegate :name, :title, to: :hosted_plan, prefix: :plan, allow_nil: true

  scope :with_hosted_plan, -> (plan_name) do
    joins(:hosted_plan).where(trial: false, 'plans.name' => plan_name)
  end

  scope :with_a_paid_hosted_plan, -> do
    with_hosted_plan(Plan::PAID_HOSTED_PLANS)
  end

  scope :preload_for_refresh_seat, -> { preload([{ namespace: :route }, :hosted_plan]) }

  DAYS_AFTER_EXPIRATION_BEFORE_REMOVING_FROM_INDEX = 7

  # We set a 7 days as the threshold for expiration before removing them from
  # the index
  def self.yield_long_expired_indexed_namespaces(&blk)
    # Since the gitlab_subscriptions table will keep growing in size and the
    # number of expired subscriptions will keep growing it is best to use
    # `each_batch` to ensure we don't end up timing out the query. This may
    # mean that the number of queries keeps growing but each one should be
    # incredibly fast.
    subscriptions = GitlabSubscription.where('end_date < ?', Date.today - DAYS_AFTER_EXPIRATION_BEFORE_REMOVING_FROM_INDEX)
    subscriptions.each_batch(column: :namespace_id) do |relation|
      ElasticsearchIndexedNamespace.where(namespace_id: relation.select(:namespace_id)).each do |indexed_namespace|
        blk.call indexed_namespace
      end
    end
  end

  def legacy?
    start_date < EOA_ROLLOUT_DATE.to_date
  end

  def calculate_seats_in_use
    namespace.billable_members_count
  end

  # The purpose of max_seats_used is similar to what we do for EE licenses
  # with the historical max. We want to know how many extra users the customer
  # has added to their group (users above the number purchased on their subscription).
  # Then, on the next month we're going to automatically charge the customers for those extra users.
  def calculate_seats_owed
    return 0 unless has_a_paid_hosted_plan?

    [0, max_seats_used - seats].max
  end

  # Refresh seat related attribute (without persisting them)
  def refresh_seat_attributes!
    self.seats_in_use = calculate_seats_in_use
    self.max_seats_used = [max_seats_used, seats_in_use].max
    self.seats_owed = calculate_seats_owed
  end

  def has_a_paid_hosted_plan?(include_trials: false)
    (include_trials || !trial?) &&
      seats > 0 &&
      Plan::PAID_HOSTED_PLANS.include?(plan_name)
  end

  def expired?
    return false unless end_date

    end_date < Date.current
  end

  def upgradable?
    return false if [::Plan::GOLD, ::Plan::ULTIMATE].include?(plan_name)

    has_a_paid_hosted_plan? &&
      !expired? &&
      plan_name != Plan::PAID_HOSTED_PLANS[-1]
  end

  def plan_code=(code)
    code ||= Plan::FREE

    self.hosted_plan = Plan.find_by(name: code)
  end

  # We need to show seats in use for free or trial subscriptions
  # in order to make it easy for customers to get this information.
  def seats_in_use
    return super unless Feature.enabled?(:seats_in_use_for_free_or_trial)
    return super if has_a_paid_hosted_plan?

    seats_in_use_now
  end

  def trial_extended_or_reactivated?
    trial_extension_type.present?
  end

  def trial_days_remaining
    (trial_ends_on - Date.current).to_i
  end

  def trial_duration
    (trial_ends_on - trial_starts_on).to_i
  end

  def trial_days_used
    trial_duration - trial_days_remaining
  end

  def trial_percentage_complete(decimal_places = 2)
    (trial_days_used / trial_duration.to_f * 100).round(decimal_places)
  end

  private

  def seats_in_use_now
    strong_memoize(:seats_in_use_now) do
      calculate_seats_in_use
    end
  end

  def log_previous_state_for_update
    attrs = self.attributes.merge(self.attributes_in_database)
    log_previous_state_to_history(:gitlab_subscription_updated, attrs)
  end

  def log_previous_state_for_destroy
    attrs = self.attributes
    log_previous_state_to_history(:gitlab_subscription_destroyed, attrs)
  end

  def log_previous_state_to_history(change_type, attrs = {})
    attrs['gitlab_subscription_created_at'] = attrs['created_at']
    attrs['gitlab_subscription_updated_at'] = attrs['updated_at']
    attrs['gitlab_subscription_id'] = self.id
    attrs['change_type'] = change_type

    omitted_attrs = %w(id created_at updated_at seats_in_use seats_owed)

    GitlabSubscriptionHistory.create(attrs.except(*omitted_attrs))
  end

  def automatically_index_in_elasticsearch?
    return false unless ::Gitlab.dev_env_or_com?
    return false if expired?

    # We only index paid groups on dot com for now.
    # If the namespace is in trial, seats will be ignored.
    Plan::PAID_HOSTED_PLANS.include?(plan_name) && (trial? || seats > 0)
  end

  # Kick off Elasticsearch indexing for paid groups with new or upgraded paid, hosted subscriptions
  # Uses safe_find_or_create_by to avoid ActiveRecord::RecordNotUnique exception when upgrading from
  # one paid plan to another paid plan
  def index_namespace
    return unless automatically_index_in_elasticsearch?

    ElasticsearchIndexedNamespace.safe_find_or_create_by!(namespace_id: namespace_id)
  end
end
