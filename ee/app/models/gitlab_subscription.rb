# frozen_string_literal: true

class GitlabSubscription < ApplicationRecord
  include EachBatch
  include Gitlab::Utils::StrongMemoize
  include AfterCommitQueue

  EOA_ROLLOUT_DATE = '2021-01-26'

  enum trial_extension_type: { extended: 1, reactivated: 2 }

  attribute :start_date, default: -> { Date.today }

  before_update :set_max_seats_used_changed_at
  before_update :log_previous_state_for_update
  before_update :reset_seats_for_new_term
  before_update :publish_subscription_renewed_event

  after_commit :index_namespace, on: [:create, :update]
  after_destroy_commit :log_previous_state_for_destroy

  belongs_to :namespace
  belongs_to :hosted_plan, class_name: 'Plan'

  validates :seats, :start_date, presence: true
  validates :namespace_id, uniqueness: true, presence: true

  delegate :name, :title, to: :hosted_plan, prefix: :plan, allow_nil: true
  delegate :exclude_guests?, to: :namespace

  scope :with_hosted_plan, -> (plan_name) do
    joins(:hosted_plan).where(trial: false, 'plans.name' => plan_name)
  end

  scope :with_a_paid_hosted_plan, -> do
    with_hosted_plan(Plan::PAID_HOSTED_PLANS)
  end

  scope :preload_for_refresh_seat, -> { preload([{ namespace: :route }, :hosted_plan]) }

  scope :max_seats_used_changed_between, -> (from:, to:) do
    where('max_seats_used_changed_at >= ?', from)
      .where('max_seats_used_changed_at <= ?', to)
  end

  DAYS_AFTER_EXPIRATION_BEFORE_REMOVING_FROM_INDEX = 30

  # We set a threshold for expiration before removing them from
  # the index
  def self.yield_long_expired_indexed_namespaces(&blk)
    # Since the gitlab_subscriptions table will keep growing in size and the
    # number of expired subscriptions will keep growing it is best to use
    # `each_batch` to ensure we don't end up timing out the query. This may
    # mean that the number of queries keeps growing but each one should be
    # incredibly fast.
    subscriptions = GitlabSubscription.where('end_date < ?', Date.today - DAYS_AFTER_EXPIRATION_BEFORE_REMOVING_FROM_INDEX)
    subscriptions.each_batch(column: :namespace_id) do |relation|
      ElasticsearchIndexedNamespace.where(namespace_id: relation.select(:namespace_id)).each(&blk)
    end
  end

  def legacy?
    start_date < EOA_ROLLOUT_DATE.to_date
  end

  def calculate_seats_in_use
    namespace.billed_user_ids[:user_ids].count
  end

  # The purpose of max_seats_used is similar to what we do for EE licenses
  # with the historical max. We want to know how many extra users the customer
  # has added to their group (users above the number purchased on their subscription).
  # Then, on the next month we're going to automatically charge the customers for those extra users.
  def calculate_seats_owed
    return 0 unless has_a_paid_hosted_plan?

    [0, max_seats_used - seats].max
  end

  def seats_remaining
    [0, seats - max_seats_used.to_i].max
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
    return false if ::Plan::TOP_PLANS.include?(plan_name)

    has_a_paid_hosted_plan? && !expired?
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
    duration = trial_duration - trial_days_remaining
    duration.nonzero? || 1 # prevent showing 0 on day 1 of a trial
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

    GitlabSubscriptionHistory.create_from_change(:gitlab_subscription_updated, attrs)
  end

  def log_previous_state_for_destroy
    GitlabSubscriptionHistory.create_from_change(:gitlab_subscription_destroyed, self.attributes)
  end

  def automatically_index_in_elasticsearch?
    return false unless ::Gitlab.com?
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

  # If the subscription starts a new term, the dates will change. We reset max_seats_used
  # and seats_owed so that we don't carry it over from the previous term
  def reset_seats_for_new_term
    return unless new_term?

    self.max_seats_used = attributes['seats_in_use']
    self.seats_owed = calculate_seats_owed
    self.max_seats_used_changed_at = nil
  end

  def publish_subscription_renewed_event
    return unless new_term?

    run_after_commit do
      Gitlab::EventStore.publish(GitlabSubscriptions::RenewedEvent.new(data: { namespace_id: namespace_id }))
    end
  end

  def set_max_seats_used_changed_at
    return if new_term? || !max_seats_used_changed?

    self.max_seats_used_changed_at = Time.current
  end

  def new_term?
    persisted? && start_date_changed? && end_date_changed? &&
      (end_date_was.nil? || start_date >= end_date_was)
  end
end
