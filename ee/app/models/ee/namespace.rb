# frozen_string_literal: true

module EE
  # Namespace EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Namespace` model
  module Namespace
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Utils::StrongMemoize
    include Ci::NamespaceSettings

    NAMESPACE_PLANS_TO_LICENSE_PLANS = {
      ::Plan::BRONZE => License::STARTER_PLAN,
      [::Plan::SILVER, ::Plan::PREMIUM, ::Plan::PREMIUM_TRIAL] => License::PREMIUM_PLAN,
      [::Plan::GOLD, ::Plan::ULTIMATE, ::Plan::ULTIMATE_TRIAL, ::Plan::OPEN_SOURCE] => License::ULTIMATE_PLAN
    }.freeze

    LICENSE_PLANS_TO_NAMESPACE_PLANS = NAMESPACE_PLANS_TO_LICENSE_PLANS.invert.freeze
    TEMPORARY_STORAGE_INCREASE_DAYS = 30

    prepended do
      include EachBatch

      has_one :namespace_limit, inverse_of: :namespace
      has_one :gitlab_subscription
      has_one :elasticsearch_indexed_namespace
      has_one :upcoming_reconciliation, inverse_of: :namespace, class_name: "GitlabSubscriptions::UpcomingReconciliation"

      has_many :compliance_management_frameworks, class_name: "ComplianceManagement::Framework"

      has_many :ci_minutes_additional_packs, class_name: "Ci::Minutes::AdditionalPack"

      has_one :security_orchestration_policy_configuration,
              class_name: 'Security::OrchestrationPolicyConfiguration',
              foreign_key: :namespace_id,
              inverse_of: :namespace

      accepts_nested_attributes_for :gitlab_subscription, update_only: true
      accepts_nested_attributes_for :namespace_limit

      scope :include_gitlab_subscription, -> { includes(:gitlab_subscription) }
      scope :include_gitlab_subscription_with_hosted_plan, -> { includes(gitlab_subscription: :hosted_plan) }
      scope :join_gitlab_subscription, -> { joins("LEFT OUTER JOIN gitlab_subscriptions ON gitlab_subscriptions.namespace_id=namespaces.id") }

      scope :in_active_trial, -> do
        left_joins(gitlab_subscription: :hosted_plan)
          .where(gitlab_subscriptions: { trial: true, trial_ends_on: Date.today.. })
      end

      scope :not_in_active_trial, -> do
        left_joins(gitlab_subscription: :hosted_plan)
          .where(gitlab_subscriptions: { trial: [nil, false] })
          .or(GitlabSubscription.where(trial_ends_on: ..Date.yesterday))
      end

      scope :in_default_plan, -> do
        left_joins(gitlab_subscription: :hosted_plan)
          .where(plans: { name: [nil, *::Plan.default_plans] })
      end

      scope :eligible_for_trial, -> do
        left_joins(gitlab_subscription: :hosted_plan)
          .where(
            parent_id: nil,
            gitlab_subscriptions: { trial: [nil, false], trial_ends_on: [nil] },
            plans: { name: [nil, *::Plan::PLANS_ELIGIBLE_FOR_TRIAL] }
          )
      end

      scope :with_feature_available_in_plan, -> (feature) do
        plans = GitlabSubscriptions::Features.saas_plans_with_feature(feature)
        matcher = ::Plan.where(name: plans)
          .joins(:hosted_subscriptions)
          .where("gitlab_subscriptions.namespace_id = namespaces.id")
          .select('1')
        where("EXISTS (?)", matcher)
      end

      scope :without_last_ci_minutes_notification, -> do
        where.not(last_ci_minutes_notification_at: nil)
          .or(where.not(last_ci_minutes_usage_notification_level: nil))
      end

      delegate :additional_purchased_storage_size, :additional_purchased_storage_size=,
        :additional_purchased_storage_ends_on, :additional_purchased_storage_ends_on=,
        :temporary_storage_increase_ends_on, :temporary_storage_increase_ends_on=,
        to: :namespace_limit, allow_nil: true

      delegate :email, to: :owner, allow_nil: true, prefix: true
      delegate :exclude_from_free_user_cap?, to: :namespace_settings, allow_nil: true # rubocop:disable Gitlab/DelegatePredicateMethods
      delegate :include_for_free_user_cap_preview?, to: :namespace_settings, allow_nil: true # rubocop:disable Gitlab/DelegatePredicateMethods

      # Opportunistically clear the +file_template_project_id+ if invalid
      before_validation :clear_file_template_project_id

      validate :validate_shared_runner_minutes_support

      validates :max_pages_size,
                numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true,
                                less_than: ::Gitlab::Pages::MAX_SIZE / 1.megabyte }

      delegate :trial_ends_on, :trial_starts_on, :trial_days_remaining,
        :trial_percentage_complete, to: :gitlab_subscription, allow_nil: true

      before_create :sync_membership_lock_with_parent

      # Changing the plan or other details may invalidate this cache
      before_save :clear_feature_available_cache

      after_commit :sync_name_with_customers_dot, on: :update, if: -> { name_previously_changed? && !project_namespace? }

      def temporary_storage_increase_enabled?
        !!namespace_limit&.temporary_storage_increase_enabled?
      end

      def eligible_for_temporary_storage_increase?
        !!namespace_limit&.eligible_for_temporary_storage_increase?
      end

      def trial?
        !!gitlab_subscription&.trial?
      end

      def upgradable?
        !!gitlab_subscription&.upgradable?
      end

      def trial_extended_or_reactivated?
        !!gitlab_subscription&.trial_extended_or_reactivated?
      end
    end

    # Only groups can be marked for deletion
    def marked_for_deletion?
      false
    end

    def namespace_limit
      limit = has_parent? ? root_ancestor.namespace_limit : super

      limit.presence || build_namespace_limit
    end

    override :move_dir
    def move_dir
      succeeded = super

      if succeeded
        all_projects.each do |project|
          ::Geo::RepositoryRenamedEventStore.new(
            project,
            old_path: project.path,
            old_path_with_namespace: old_path_with_namespace_for(project)
          ).create!
        end
      end

      succeeded
    end

    def old_path_with_namespace_for(project)
      project.full_path.sub(/\A#{Regexp.escape(full_path)}/, full_path_before_last_save)
    end

    # Checks features (i.e. https://about.gitlab.com/pricing/) availability
    # for a given Namespace plan. This method should consider ancestor groups
    # being licensed.
    override :licensed_feature_available?
    def licensed_feature_available?(feature)
      available_features = strong_memoize(:licensed_feature_available) do
        Hash.new do |h, f|
          h[f] = load_feature_available(f)
        end
      end

      available_features[feature]
    end

    def feature_available_in_plan?(feature)
      available_features = strong_memoize(:features_available_in_plan) do
        Hash.new do |h, f|
          h[f] = (plans.map(&:name) & GitlabSubscriptions::Features.saas_plans_with_feature(f)).any?
        end
      end

      available_features[feature]
    end

    def feature_available_non_trial?(feature)
      feature_available?(feature.to_sym) && !root_ancestor.trial_active?
    end

    override :actual_plan
    def actual_plan
      strong_memoize(:actual_plan) do
        next ::Plan.default unless ::Gitlab.com?

        if parent_id
          root_ancestor.actual_plan
        else
          subscription = gitlab_subscription || generate_subscription
          hosted_plan_for(subscription) || ::Plan.free
        end
      end
    end

    def plan_name_for_upgrading
      return ::Plan::FREE if trial_active?

      actual_plan_name
    end

    def over_storage_limit?
      ::Gitlab::CurrentSettings.enforce_namespace_storage_limit? &&
      ::Feature.enabled?(:namespace_storage_limit, root_ancestor) &&
        root_ancestor.root_storage_size.above_size_limit?
    end

    def total_repository_size_excess
      strong_memoize(:total_repository_size_excess) do
        total_excess = (total_repository_size_arel - repository_size_limit_arel).sum

        projects_for_repository_size_excess.pluck(total_excess).first || 0
      end
    end

    def repository_size_excess_project_count
      strong_memoize(:repository_size_excess_project_count) do
        projects_for_repository_size_excess.count
      end
    end

    def total_repository_size
      strong_memoize(:total_repository_size) do
        all_projects
          .joins(:statistics)
          .pluck(total_repository_size_arel.sum).first || 0 # rubocop:disable Rails/Pick
      end
    end

    def contains_locked_projects?
      total_repository_size_excess > additional_purchased_storage_size.megabytes
    end

    def actual_size_limit
      ::Gitlab::CurrentSettings.repository_size_limit
    end

    def sync_membership_lock_with_parent
      if parent&.membership_lock?
        self.membership_lock = true
      end
    end

    def ci_minutes_usage
      strong_memoize(:ci_minutes_usage) do
        ::Ci::Minutes::Usage.new(self)
      end
    end

    # The same method name is used also at project level
    def shared_runners_minutes_limit_enabled?
      any_project_with_shared_runners_enabled? && ci_minutes_usage.limit_enabled?
    end

    def any_project_with_shared_runners_enabled?
      Rails.cache.fetch([self, :has_project_with_shared_runners_enabled], expires_in: 5.minutes) do
        any_project_with_shared_runners_enabled_with_cte?
      end
    end

    # These helper methods are required to not break the Namespace API.
    def memoized_plans=(plans)
      @plans = plans # rubocop: disable Gitlab/ModuleWithInstanceVariables
    end

    def plans
      @plans ||=
        if parent_id
          ::Plan.hosted_plans_for_namespaces(self_and_ancestors.select(:id))
        else
          ::Plan.hosted_plans_for_namespaces(self)
        end
    end

    def has_free_or_no_subscription?
      # this is a side-effect free version of checking if a namespace
      # is on a free plan or has no plan - see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/80839#note_851566461
      strong_memoize(:has_free_or_no_subscription) do
        subscription = root_ancestor.gitlab_subscription

        # there is a chance that subscriptions do not have a plan https://gitlab.com/gitlab-org/gitlab/-/merge_requests/81432#note_858514873
        if subscription&.plan_name
          subscription.plan_name == ::Plan::FREE
        else
          true
        end
      end
    end

    # When a purchasing a GL.com plan for a User namespace
    # we only charge for a single user.
    # This method is overwritten in Group where we made the calculation
    # for Group namespaces.
    def billable_members_count(_requested_hosted_plan = nil)
      1
    end

    # When a purchasing a GL.com plan for a User namespace
    # we only charge for a single user.
    # This method is overwritten in Group where we made the calculation
    # for Group namespaces.
    def billed_user_ids(_requested_hosted_plan = nil)
      {
        user_ids: [owner_id],
        group_member_user_ids: [],
        project_member_user_ids: [],
        shared_group_user_ids: [],
        shared_project_user_ids: []
      }
    end

    def free_plan_members_count
      free_plan_user_ids.count
    end

    def eligible_for_trial?
      ::Gitlab.com? &&
        !has_parent? &&
        never_had_trial? &&
        plan_eligible_for_trial?
    end

    # Be sure to call this on root_ancestor since plans are only associated
    # with the top-level namespace, not with subgroups.
    def trial_active?
      trial? && trial_ends_on.present? && trial_ends_on >= Date.today
    end

    def can_extend_trial?
      return false unless ::Feature.enabled?(:allow_extend_reactivate_trial)

      trial_active? && !trial_extended_or_reactivated?
    end

    def can_reactivate_trial?
      return false unless ::Feature.enabled?(:allow_extend_reactivate_trial)

      !trial_active? && !never_had_trial? && !trial_extended_or_reactivated? && free_plan?
    end

    def never_had_trial?
      trial_ends_on.nil?
    end

    def trial_expired?
      trial_ends_on.present? && trial_ends_on < Date.today
    end

    # A namespace may not have a file template project
    def checked_file_template_project
      nil
    end

    def checked_file_template_project_id
      checked_file_template_project&.id
    end

    def store_security_reports_available?
      feature_available?(:sast) ||
      feature_available?(:secret_detection) ||
      feature_available?(:dependency_scanning) ||
      feature_available?(:container_scanning) ||
      feature_available?(:cluster_image_scanning) ||
      feature_available?(:dast) ||
      feature_available?(:coverage_fuzzing) ||
      feature_available?(:api_fuzzing)
    end

    def default_plan?
      actual_plan_name == ::Plan::DEFAULT
    end

    def free_plan?
      actual_plan_name == ::Plan::FREE
    end

    def bronze_plan?
      actual_plan_name == ::Plan::BRONZE
    end

    def silver_plan?
      actual_plan_name == ::Plan::SILVER
    end

    def premium_plan?
      actual_plan_name == ::Plan::PREMIUM
    end

    def premium_trial_plan?
      actual_plan_name == ::Plan::PREMIUM_TRIAL
    end

    def gold_plan?
      actual_plan_name == ::Plan::GOLD
    end

    def ultimate_plan?
      actual_plan_name == ::Plan::ULTIMATE
    end

    def ultimate_trial_plan?
      actual_plan_name == ::Plan::ULTIMATE_TRIAL
    end

    def opensource_plan?
      actual_plan_name == ::Plan::OPEN_SOURCE
    end

    def plan_eligible_for_trial?
      ::Plan::PLANS_ELIGIBLE_FOR_TRIAL.include?(actual_plan_name)
    end

    def free_personal?
      user_namespace? && !paid?
    end

    def use_elasticsearch?
      ::Gitlab::CurrentSettings.elasticsearch_indexes_namespace?(self)
    end

    def invalidate_elasticsearch_indexes_cache!
      ::Gitlab::CurrentSettings.invalidate_elasticsearch_indexes_cache_for_namespace!(self.id)
    end

    def elastic_namespace_ancestry
      separator = '-'
      self_and_ancestor_ids(hierarchy_order: :desc).join(separator) + separator
    end

    def enable_temporary_storage_increase!
      update(temporary_storage_increase_ends_on: TEMPORARY_STORAGE_INCREASE_DAYS.days.from_now)
    end

    def additional_repo_storage_by_namespace_enabled?
      !::Feature.enabled?(:namespace_storage_limit, self) &&
        ::Gitlab::CurrentSettings.automatic_purchased_storage_allocation?
    end

    def root_storage_size
      klass = additional_repo_storage_by_namespace_enabled? ? RootExcessStorageSize : RootStorageSize
      klass.new(self)
    end

    def user_cap_available?
      return false unless group_namespace?
      return false unless ::Gitlab.com?

      ::Feature.enabled?(:saas_user_caps, root_ancestor)
    end

    def apply_user_cap?
      user_cap_available? || enforce_free_user_cap?
    end

    def enforce_free_user_cap?
      free_user_cap.enforce_cap?
    end

    def user_limit_reached?(use_cache: false)
      free_user_cap.reached_limit?
    end

    def capacity_left_for_user?(user)
      return true unless apply_user_cap?
      return true if ::Member.in_hierarchy(root_ancestor).with_user(user).with_state(:active).exists?

      !user_limit_reached?
    end

    def free_plan_user_ids
      strong_memoize(:free_plan_user_ids) do
        billed_users.pluck(:id)
      end
    end

    def expire_free_plan_members_count_cache
      clear_memoization(:free_plan_user_ids)
    end

    def trimmable_user_ids
      strong_memoize(:trimmable_user_ids) do
        active_members = ::Member.in_hierarchy(self).active_state

        users_without_project_bots(active_members)
          .with_state(:active)
          .pluck(:id)
      end
    end

    def recent_activity_by_users_in_hierarchy
      strong_memoize(:recent_activity_by_users_in_hierarchy) do
        ::Event.from_union(
          [
            ::Event.where(author: trimmable_user_ids).where(project: root_ancestor.all_projects),
            ::Event.where(author: trimmable_user_ids).where(group: root_ancestor.self_and_descendants)
          ]
        ).group(:author_id).maximum(:id)
      end
    end

    def take_high_activity_user_ids(user_ids, count = ::Namespaces::FreeUserCap::FREE_USER_LIMIT)
      user_ids
        .sort_by { |e| -recent_activity_by_users_in_hierarchy[e].to_i }
        .take(count)
    end

    def staying_in_user_ids
      strong_memoize(:staying_in_user_ids) do
        if trimmable_user_ids.count <= ::Namespaces::FreeUserCap::FREE_USER_LIMIT
          trimmable_user_ids
        else
          if owner_ids.count == ::Namespaces::FreeUserCap::FREE_USER_LIMIT
            owner_ids
          elsif owner_ids.count > ::Namespaces::FreeUserCap::FREE_USER_LIMIT
            take_high_activity_user_ids(owner_ids)
          else
            additional_non_owners = take_high_activity_user_ids(trimmable_user_ids, ::Namespaces::FreeUserCap::FREE_USER_LIMIT) - owner_ids
            owners_and_users = take_high_activity_user_ids(owner_ids) + additional_non_owners
            owners_and_users.take(::Namespaces::FreeUserCap::FREE_USER_LIMIT)
          end
        end
      end
    end

    def memberships_to_be_deactivated
      ::Member
        .in_hierarchy(self)
        .active_state
        .excluding_users(staying_in_user_ids)
    end

    def exclude_guests?
      false
    end

    def owner_ids
      [owner.id]
    end

    def all_security_orchestration_policy_configurations
      return Array.wrap(security_orchestration_policy_configuration) if self_and_ancestor_ids.blank?

      security_orchestration_policies_for_namespaces(self_and_ancestor_ids)
    end

    def all_inherited_security_orchestration_policy_configurations
      return [] if ancestor_ids.blank?

      security_orchestration_policies_for_namespaces(ancestor_ids)
    end

    private

    def security_orchestration_policies_for_namespaces(namespace_ids)
      ::Security::OrchestrationPolicyConfiguration
        .for_namespace(namespace_ids)
        .with_project_and_namespace
        .select { |configuration| configuration&.policy_configuration_valid? }
    end

    def free_user_cap
      @free_user_cap ||= ::Namespaces::FreeUserCap::Standard.new(self)
    end

    # Members belonging directly to Projects within user/project namespaces
    def billed_users
      # this will include the namespace owner(user namespace) as well
      members = ::ProjectMember.without_invites_and_requests.where(source_id: ::Project.in_namespace(self))

      users_without_project_bots(members).with_state(:active)
    end

    def users_without_project_bots(members)
      ::User.id_in(members.distinct.select(:user_id)).without_project_bot
    end

    def any_project_with_shared_runners_enabled_with_cte?
      projects_query = if user_namespace?
                         projects
                       else
                         cte = ::Gitlab::SQL::CTE.new(:namespace_self_and_descendants_cte, self_and_descendant_ids)

                         ::Project
                           .with(cte.to_arel)
                           .from([::Project.table_name, cte.table.name].join(', '))
                           .where(::Project.arel_table[:namespace_id].eq(cte.table[:id]))
                       end

      projects_query.with_shared_runners.any?
    end

    def validate_shared_runner_minutes_support
      return if root?

      if shared_runners_minutes_limit_changed?
        errors.add(:shared_runners_minutes_limit, 'is not supported for this namespace')
      end
    end

    def clear_feature_available_cache
      clear_memoization(:licensed_feature_available)
    end

    def sync_name_with_customers_dot
      return unless ::Gitlab.com?
      return if user_namespace? && owner.privatized_by_abuse_automation?

      ::Namespaces::SyncNamespaceNameWorker.perform_async(id)
    end

    def load_feature_available(feature)
      globally_available = License.feature_available?(feature)

      if ::Gitlab::CurrentSettings.should_check_namespace_plan?
        globally_available && feature_available_in_plan?(feature)
      else
        globally_available
      end
    end

    def clear_file_template_project_id
      return unless has_attribute?(:file_template_project_id)
      return if checked_file_template_project_id.present?

      self.file_template_project_id = nil
    end

    def generate_subscription
      return unless persisted?
      return if ::Gitlab::Database.read_only?

      create_gitlab_subscription(
        plan_code: Plan::FREE,
        trial: trial_active?,
        start_date: created_at,
        seats: 0
      )
    end

    def total_repository_size_arel
      arel_table = ::ProjectStatistics.arel_table
      arel_table[:repository_size] + arel_table[:lfs_objects_size]
    end

    def projects_for_repository_size_excess
      projects_with_limits = ::Project.without_unlimited_repository_size_limit

      if actual_size_limit.to_i > 0
        # When the instance or namespace level limit is set, we need to include those without project level limits
        projects_with_limits = projects_with_limits.or(::Project.without_repository_size_limit)
      end

      all_projects
        .merge(projects_with_limits)
        .with_total_repository_size_greater_than(repository_size_limit_arel)
    end

    def repository_size_limit_arel
      instance_size_limit = actual_size_limit.to_i

      if instance_size_limit > 0
        self.class.arel_table.coalesce(
          ::Project.arel_table[:repository_size_limit],
          instance_size_limit
        )
      else
        ::Project.arel_table[:repository_size_limit]
      end
    end

    def hosted_plan_for(subscription)
      return unless subscription

      plan = subscription.hosted_plan
      if plan && !subscription.legacy?
        ::Subscriptions::NewPlanPresenter.new(plan)
      else
        plan
      end
    end
  end
end
