# frozen_string_literal: true

module EE
  # User EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `User` model
  module User
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Utils::StrongMemoize

    include AuditorUserHelper

    DEFAULT_ROADMAP_LAYOUT = 'months'
    DEFAULT_GROUP_VIEW = 'details'
    ELASTICSEARCH_TRACKED_FIELDS = %w[id username email public_email name admin state organization
                                      timezone external otp_required_for_login].freeze
    GROUP_WITH_AI_ENABLED_CACHE_PERIOD = 1.hour

    prepended do
      include UsageStatistics
      include PasswordComplexity
      include IdentityVerifiable
      include Elastic::ApplicationVersionedSearch
      include Ai::Model

      EMAIL_OPT_IN_SOURCE_ID_GITLAB_COM = 1

      # We aren't using the `auditor?` method for the `if` condition here
      # because `auditor?` returns `false` when the `auditor` column is `true`
      # and the auditor add-on absent. We want to run this validation
      # regardless of the add-on's presence, so we need to check the `auditor`
      # column directly.
      validate :auditor_requires_license_add_on, if: :auditor
      validate :cannot_be_admin_and_auditor

      after_create :perform_user_cap_check
      after_update :email_changed_hook, if: :saved_change_to_email?

      delegate :shared_runners_minutes_limit, :shared_runners_minutes_limit=,
        :extra_shared_runners_minutes_limit, :extra_shared_runners_minutes_limit=,
        to: :namespace
      delegate :provisioned_by_group, :provisioned_by_group=,
        :provisioned_by_group_id, :provisioned_by_group_id=,
        :onboarding_step_url=,
        to: :user_detail, allow_nil: true

      delegate :code_suggestions_enabled?, :code_suggestions, :code_suggestions=,
        to: :namespace

      delegate :enabled_zoekt?, :enabled_zoekt, :enabled_zoekt=,
        to: :user_preference

      has_many :epics,                    foreign_key: :author_id
      has_many :test_reports,             foreign_key: :author_id, inverse_of: :author, class_name: 'RequirementsManagement::TestReport'
      has_many :assigned_epics,           foreign_key: :assignee_id, class_name: "Epic"
      has_many :path_locks,               dependent: :destroy # rubocop: disable Cop/ActiveRecordDependent
      has_many :vulnerability_feedback, foreign_key: :author_id, class_name: 'Vulnerabilities::Feedback'
      has_many :vulnerability_state_transitions, foreign_key: :author_id, class_name: 'Vulnerabilities::StateTransition', inverse_of: :author
      has_many :commented_vulnerability_feedback, foreign_key: :comment_author_id, class_name: 'Vulnerabilities::Feedback'
      has_many :boards_epic_user_preferences, class_name: 'Boards::EpicUserPreference', inverse_of: :user
      has_many :epic_board_recent_visits, class_name: 'Boards::EpicBoardRecentVisit', inverse_of: :user

      has_many :approvals,                dependent: :destroy # rubocop: disable Cop/ActiveRecordDependent
      has_many :approvers,                dependent: :destroy # rubocop: disable Cop/ActiveRecordDependent

      has_many :minimal_access_group_members, -> { where(access_level: [::Gitlab::Access::MINIMAL_ACCESS]) }, class_name: 'GroupMember'
      has_many :minimal_access_groups, through: :minimal_access_group_members, source: :group
      has_many :elevated_members, -> { elevated_guests }, class_name: 'Member'

      has_many :users_ops_dashboard_projects
      has_many :ops_dashboard_projects, through: :users_ops_dashboard_projects, source: :project
      has_many :users_security_dashboard_projects
      has_many :security_dashboard_projects, through: :users_security_dashboard_projects, source: :project

      has_many :group_saml_identities, -> { where.not(saml_provider_id: nil) }, class_name: "::Identity"

      # Protected Branch Access
      has_many :protected_branch_merge_access_levels, dependent: :destroy, class_name: "::ProtectedBranch::MergeAccessLevel" # rubocop:disable Cop/ActiveRecordDependent
      has_many :protected_branch_push_access_levels, dependent: :destroy, class_name: "::ProtectedBranch::PushAccessLevel" # rubocop:disable Cop/ActiveRecordDependent
      has_many :protected_branch_unprotect_access_levels, dependent: :destroy, class_name: "::ProtectedBranch::UnprotectAccessLevel" # rubocop:disable Cop/ActiveRecordDependent

      has_many :deployment_approvals, class_name: 'Deployments::Approval'

      has_many :smartcard_identities
      has_many :scim_identities

      has_many :board_preferences, class_name: 'BoardUserPreference', inverse_of: :user

      belongs_to :managing_group, class_name: 'Group', optional: true, inverse_of: :managed_users

      has_many :user_permission_export_uploads

      has_many :oncall_participants, -> { not_removed }, class_name: 'IncidentManagement::OncallParticipant', inverse_of: :user
      has_many :oncall_rotations, class_name: 'IncidentManagement::OncallRotation', through: :oncall_participants, source: :rotation
      has_many :oncall_schedules, -> { distinct }, class_name: 'IncidentManagement::OncallSchedule', through: :oncall_rotations, source: :schedule
      has_many :escalation_rules, -> { not_removed }, class_name: 'IncidentManagement::EscalationRule', inverse_of: :user
      has_many :escalation_policies, -> { distinct }, class_name: 'IncidentManagement::EscalationPolicy', through: :escalation_rules, source: :policy

      has_many :namespace_bans, class_name: 'Namespaces::NamespaceBan'

      has_many :workspaces, class_name: 'RemoteDevelopment::Workspace', inverse_of: :user

      has_many :dependency_list_exports, class_name: 'Dependencies::DependencyListExport', inverse_of: :author

      has_many :assigned_add_ons, class_name: 'GitlabSubscriptions::UserAddOnAssignment', inverse_of: :user

      scope :not_managed, ->(group: nil) {
        scope = where(managing_group_id: nil)
        scope = scope.or(where.not(managing_group_id: group.id)) if group
        scope
      }

      scope :managed_by, ->(group) { where(managing_group: group) }

      scope :excluding_guests, -> do
        subquery = ::Member
          .select(1)
          .where(::Member.arel_table[:user_id].eq(::User.arel_table[:id]))
          .merge(::Member.with_elevated_guests)

        where('EXISTS (?)', subquery)
      end

      scope :guests_with_elevating_role, -> do
        joins(:user_highest_role).joins(:elevated_members).where(user_highest_role: { highest_access_level: ::Gitlab::Access::GUEST })
      end

      scope :subscribed_for_admin_email, -> { where(admin_email_unsubscribed_at: nil) }
      scope :ldap, -> { joins(:identities).where('identities.provider LIKE ?', 'ldap%') }
      scope :with_provider, ->(provider) do
        joins(:identities).where(identities: { provider: provider })
      end

      scope :with_invalid_expires_at_tokens, ->(expiration_date) do
        where(id: ::PersonalAccessToken.with_invalid_expires_at(expiration_date).select(:user_id))
      end

      scope :with_scim_identities_by_extern_uid, ->(extern_uid) { joins(:scim_identities).merge(ScimIdentity.with_extern_uid(extern_uid)) }

      accepts_nested_attributes_for :namespace
      accepts_nested_attributes_for :custom_attributes

      enum roadmap_layout: { weeks: 1, months: 4, quarters: 12 }

      # User's Group preference
      # Note: When adding an option, it's value MUST equal to the last value + 1.
      enum group_view: { details: 1, security_dashboard: 2 }, _prefix: true
      scope :group_view_details, -> { where('group_view = ? OR group_view IS NULL', group_view[:details]) }
      scope :unconfirmed_and_created_before, ->(created_cut_off) { human.with_state(:active).where(confirmed_at: nil).where('created_at < ?', created_cut_off).where(sign_in_count: 0) }

      # If user cap is reached any user that is getting marked :active from :deactivated
      # should get blocked pending approval
      state_machine :state do
        after_transition deactivated: :active do |user|
          user.block_pending_approval if ::User.user_cap_reached?
        end
      end
    end

    class_methods do
      extend ::Gitlab::Utils::Override

      def visual_review_bot
        email_pattern = "visual_review%s@#{Settings.gitlab.host}"

        unique_internal(where(user_type: :visual_review_bot), 'visual-review-bot', email_pattern) do |u|
          u.bio = 'The Gitlab Visual Review feedback bot'
          u.name = 'Gitlab Visual Review Bot'
        end
      end

      def suggested_reviewers_bot
        email_pattern = "suggested-reviewers-bot%s@#{Settings.gitlab.host}"

        unique_internal(where(user_type: :suggested_reviewers_bot), 'suggested-reviewers-bot', email_pattern) do |u|
          u.bio = 'The GitLab suggested reviewers bot used for suggested reviewers'
          u.name = 'GitLab Suggested Reviewers Bot'
        end
      end

      def non_ldap
        joins('LEFT JOIN identities ON identities.user_id = users.id')
          .where('identities.provider IS NULL OR identities.provider NOT LIKE ?', 'ldap%')
      end

      def find_by_smartcard_identity(certificate_subject, certificate_issuer)
        joins(:smartcard_identities)
          .find_by(smartcard_identities: { subject: certificate_subject, issuer: certificate_issuer })
      end

      # Limits the users to those who have an identity that belongs to
      # the given SAML Provider
      def limit_to_saml_provider(saml_provider_id)
        if saml_provider_id
          joins(:identities).where(identities: { saml_provider_id: saml_provider_id })
        else
          all
        end
      end

      def billable
        scope = active.without_bots
        scope = scope.excluding_guests if License.current&.exclude_guests_from_active_count?

        scope
      end

      def user_cap_reached?
        return false unless user_cap_max.present?

        billable.limit(user_cap_max + 1).count >= user_cap_max
      end

      def user_cap_max
        ::Gitlab::CurrentSettings.new_user_signups_cap
      end

      override :random_password
      def random_password
        1000.times do
          password = super
          next unless complexity_matched? password

          return password
        end
      end

      # override
      def use_separate_indices?
        true
      end
    end

    def cannot_be_admin_and_auditor
      if admin? && auditor?
        errors.add(:admin, 'user cannot also be an Auditor.')
      end
    end

    def auditor_requires_license_add_on
      unless license_allows_auditor_user?
        errors.add(:auditor, 'user cannot be created without the "GitLab_Auditor_User" addon')
      end
    end

    def auditor?
      self.auditor && license_allows_auditor_user?
    end

    def access_level
      if auditor?
        :auditor
      else
        super
      end
    end

    def access_level=(new_level)
      new_level = new_level.to_s
      return unless %w(admin auditor regular).include?(new_level)

      self.admin = (new_level == 'admin')
      self.auditor = (new_level == 'auditor')
    end

    def email_opted_in_source
      email_opted_in_source_id == EMAIL_OPT_IN_SOURCE_ID_GITLAB_COM ? 'GitLab.com' : ''
    end

    def available_custom_project_templates(search: nil, subgroup_id: nil, project_id: nil)
      CustomProjectTemplatesFinder
        .new(current_user: self, search: search, subgroup_id: subgroup_id, project_id: project_id)
        .execute
    end

    def use_elasticsearch?
      ::Gitlab::CurrentSettings.elasticsearch_search?
    end

    override :maintaining_elasticsearch?
    def maintaining_elasticsearch?
      ::Gitlab::CurrentSettings.elasticsearch_indexing?
    end

    # override
    def maintain_elasticsearch_update
      super if update_elasticsearch?
    end

    def update_elasticsearch?
      changed_fields = previous_changes.keys
      changed_fields && (changed_fields & ELASTICSEARCH_TRACKED_FIELDS).any?
    end

    def search_membership_ancestry
      members.flat_map do |member|
        member.source&.elastic_namespace_ancestry
      end
    end

    def available_subgroups_with_custom_project_templates(group_id = nil)
      found_groups = GroupsWithTemplatesFinder.new(group_id).execute

      ::GroupsFinder.new(self, min_access_level: ::Gitlab::Access::DEVELOPER)
        .execute
        .where(id: found_groups.select(:custom_project_templates_group_id))
        .preload(:projects)
        .joins(:projects)
        .reorder(nil)
        .distinct
    end

    def roadmap_layout
      super || DEFAULT_ROADMAP_LAYOUT
    end

    def group_view
      super || DEFAULT_GROUP_VIEW
    end

    # Returns true if the user owns a group
    # that has never had a trial (now or in the past)
    def owns_group_without_trial?
      owned_groups
        .include_gitlab_subscription
        .where(parent_id: nil)
        .where(gitlab_subscriptions: { trial_ends_on: nil })
        .any?
    end

    # Returns true if the user is a Reporter or higher on any namespace
    # that is associated as a Zoekt::IndexedNamespace
    def has_zoekt_indexed_namespace?
      zoekt_indexed_namespaces.any?
    end

    def zoekt_indexed_namespaces
      ::Zoekt::IndexedNamespace.where(
        namespace: ::Namespace
          .from("(#{namespace_union_for_reporter_developer_maintainer_owned}) #{::Namespace.table_name}")
      )
    end

    # Returns true if the user is a Reporter or higher on any namespace
    # currently on a paid plan
    def has_paid_namespace?(plans: ::Plan::PAID_HOSTED_PLANS, exclude_trials: false)
      paid_namespaces(plans: plans, exclude_trials: exclude_trials).any?
    end

    def paid_namespaces(plans: ::Plan::PAID_HOSTED_PLANS, exclude_trials: false)
      paid_hosted_plans = ::Plan::PAID_HOSTED_PLANS & plans

      namespaces_with_plans = ::Namespace
        .from("(#{namespace_union_for_reporter_developer_maintainer_owned}) #{::Namespace.table_name}")
        .include_gitlab_subscription
        .where(gitlab_subscriptions: { hosted_plan: ::Plan.where(name: paid_hosted_plans) })
        .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/419988")

      if exclude_trials
        return namespaces_with_plans
          .where(gitlab_subscriptions: { trial: [nil, false] })
          .or(namespaces_with_plans.where(gitlab_subscriptions: { trial_ends_on: ..Date.yesterday }))
          .select(:id)
      end

      namespaces_with_plans.select(:id)
    end

    # Returns true if the user is an Owner on any namespace currently on
    # a paid plan
    def owns_paid_namespace?(plans: ::Plan::PAID_HOSTED_PLANS)
      ::Namespace
        .from("(#{namespace_union_for_owned}) #{::Namespace.table_name}")
        .include_gitlab_subscription
        .where(gitlab_subscriptions: { hosted_plan: ::Plan.where(name: plans) })
        .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/419988")
        .any?
    end

    def manageable_namespaces_eligible_for_trial
      owned_groups.eligible_for_trial.order(:name)
    end

    override :has_current_license?
    def has_current_license?
      License.current.present?
    end

    def using_license_seat?
      active? &&
        !internal? &&
        !project_bot? &&
        !service_account? &&
        has_current_license? &&
        paid_in_current_license?
    end

    def using_gitlab_com_seat?(namespace)
      ::Gitlab.com? &&
      namespace.present? &&
      active? &&
      !namespace.root_ancestor.free_plan? &&
      namespace.root_ancestor.billed_user_ids[:user_ids].include?(self.id)
    end

    def group_sso?(group)
      return false unless group

      if group_saml_identities.loaded?
        group_saml_identities.any? { |identity| identity.saml_provider.group_id == group.id }
      else
        group_saml_identities.where(saml_provider: group.saml_provider).any?
      end
    end

    def group_managed_account?
      managing_group.present?
    end

    def managed_by?(user)
      self.group_managed_account? && self.managing_group.owned_by?(user)
    end

    override :ldap_sync_time
    def ldap_sync_time
      ::Gitlab.config.ldap['sync_time']
    end

    override :allow_password_authentication_for_web?
    def allow_password_authentication_for_web?(*)
      return false if group_managed_account?
      return false if user_authorized_by_provisioning_group?

      super
    end

    override :allow_password_authentication_for_git?
    def allow_password_authentication_for_git?(*)
      return false if group_managed_account?
      return false if user_authorized_by_provisioning_group?

      super
    end

    override :password_based_login_forbidden?
    def password_based_login_forbidden?
      user_authorized_by_provisioning_group? || super
    end

    def user_authorized_by_provisioning_group?
      user_detail.provisioned_by_group? && ::Feature.enabled?(:block_password_auth_for_saml_users, user_detail.provisioned_by_group, type: :ops)
    end

    def authorized_by_provisioning_group?(group)
      user_authorized_by_provisioning_group? && provisioned_by_group == group
    end

    def enterprise_user_of_group?(group)
      user_detail.enterprise_group_id == group.id
    end

    def enterprise_user?
      user_detail.enterprise_group_id.present?
    end

    def gitlab_employee?
      gitlab_team_member?
    end

    def gitlab_team_member?
      human? && gitlab_com_member?
    end

    def gitlab_service_user?
      service_user? && gitlab_com_member?
    end

    def gitlab_bot?
      bot? && gitlab_com_member?
    end

    def security_dashboard
      InstanceSecurityDashboard.new(self)
    end

    # Returns the groups a user has access to, either through a membership or a project authorization
    override :authorized_groups
    def authorized_groups(with_minimal_access: true)
      return super() unless with_minimal_access

      ::Group.unscoped do
        ::Group.from_union([super(), available_minimal_access_groups])
      end
    end

    def find_or_init_board_epic_preference(board_id:, epic_id:)
      boards_epic_user_preferences.find_or_initialize_by(
        board_id: board_id, epic_id: epic_id)
    end

    # GitLab.com users should not be able to remove themselves
    # when they cannot verify their local password, because it
    # isn't set (using third party authentication).
    override :can_remove_self?
    def can_remove_self?
      return true unless ::Gitlab.com?

      !password_automatically_set?
    end

    def has_required_credit_card_to_run_pipelines?(project)
      has_valid_credit_card? || !requires_credit_card_to_run_pipelines?(project)
    end

    # This is like has_required_credit_card_to_run_pipelines? except that
    # former checks whether shared runners are enabled, and this method does not.
    def has_required_credit_card_to_enable_shared_runners?(project)
      has_valid_credit_card? || !requires_credit_card_to_enable_shared_runners?(project)
    end

    def activate_based_on_user_cap?
      !blocked_auto_created_oauth_ldap_user? &&
        blocked_pending_approval? &&
        self.class.user_cap_max.present?
    end

    def blocked_auto_created_oauth_ldap_user?
      identities.any? && block_auto_created_users?
    end

    def has_valid_credit_card?
      credit_card_validated_at.present?
    end

    def privatized_by_abuse_automation?
      # Prevent abuse automation names are expected to be in the format: ghost-:id-:id. Ex: ghost-123-4567
      # More context: https://gitlab.com/gitlab-org/customers-gitlab-com/-/issues/3871 for more context on the
      private_profile? && name.match?(/\Aghost-\d+-\d+\z/)
    end

    def banned_from_namespace?(namespace)
      # Always load the entire collection to allow preloading and avoiding N+1 queries.
      namespace_bans.any? { |namespace_ban| namespace_ban.namespace == namespace }
    end

    def namespace_ban_for(namespace)
      namespace_bans.find_by!(namespace: namespace)
    end

    def custom_permission_for?(resource, permission)
      roles = if resource.is_a?(Project)
                preloaded_member_roles_for_projects([resource])[resource.id]
              else
                preloaded_member_roles_for_groups([resource])[resource.id]
              end

      roles&.include?(permission)
    end

    override :preloaded_member_roles_for_projects
    def preloaded_member_roles_for_projects(projects)
      resource_key = "member_roles_in_projects:#{self.class}:#{self.id}"

      ::Gitlab::SafeRequestLoader.execute(
        resource_key: resource_key,
        resource_ids: projects.map(&:id)
      ) do |projects|
        ::Preloaders::UserMemberRolesInProjectsPreloader.new(
          projects: projects,
          user: self
        ).execute
      end
    end

    def preloaded_member_roles_for_groups(groups)
      resource_key = "member_roles_in_groups:#{self.class}:#{self.id}"

      ::Gitlab::SafeRequestLoader.execute(
        resource_key: resource_key,
        resource_ids: groups.map(&:id)
      ) do |groups|
        ::Preloaders::UserMemberRolesInGroupsPreloader.new(
          groups: groups,
          user: self
        ).execute
      end
    end

    def can_group_owner_disable_two_factor?(group, user)
      return false unless group && user

      group.root? &&
        group_provisioned_user?(group) &&
        group.owned_by?(user)
    end

    def third_party_ai_features_enabled?
      accessible_root_groups = groups.by_parent(nil)
      return false if accessible_root_groups.empty?

      disabled_by_any_group = accessible_root_groups.reject(&:third_party_ai_features_enabled).any?
      !disabled_by_any_group
    end

    def code_suggestions_disabled_by_group?
      groups.roots.joins(:namespace_settings).where(namespace_settings: { code_suggestions: false }).any?
    end

    def any_group_with_ai_available?
      Rails.cache.fetch(['users', id, 'group_with_ai_enabled'], expires_in: GROUP_WITH_AI_ENABLED_CACHE_PERIOD) do
        member_namespaces.namespace_settings_with_ai_enabled.with_ai_supported_plan.any?
      end
    end

    protected

    override :password_required?
    def password_required?(*)
      return false if service_account? || group_managed_account?

      super
    end

    private

    def gitlab_com_member?
      ::Gitlab::Com.gitlab_com_group_member?(self)
    end
    strong_memoize_attr :gitlab_com_member?

    def group_provisioned_user?(group)
      self.provisioned_by_group_id == group.id
    end

    def block_auto_created_users?
      if ldap_user?
        provider = ldap_identity.provider

        return false unless provider
        return false unless ::Gitlab::Auth::Ldap::Config.enabled?

        ::Gitlab::Auth::Ldap::Config.new(provider).block_auto_created_users
      else
        ::Gitlab.config.omniauth.block_auto_created_users
      end
    end

    def created_after_credit_card_release_day?(project)
      created_at >= ::Users::CreditCardValidation::RELEASE_DAY ||
        ::Feature.enabled?(:ci_require_credit_card_for_old_users, project)
    end

    def requires_credit_card_to_run_pipelines?(project)
      return false unless project.shared_runners_enabled

      requires_credit_card?(project)
    end

    def requires_credit_card_to_enable_shared_runners?(project)
      requires_credit_card?(project)
    end

    def requires_credit_card?(project)
      return false unless ::Gitlab.com?
      return false unless created_after_credit_card_release_day?(project)

      root_namespace = project.root_namespace
      ci_usage = root_namespace.ci_minutes_usage

      return false if ci_usage.quota_enabled? && ci_usage.quota.any_purchased?

      if root_namespace.free_plan?
        ::Feature.enabled?(:ci_require_credit_card_on_free_plan, project)
      elsif root_namespace.trial?
        ::Feature.enabled?(:ci_require_credit_card_on_trial_plan, project)
      else
        false
      end
    end

    def namespace_union_for_owned(select = :id)
      ::Gitlab::SQL::Union.new(
        [
          ::Namespace.select(select).where(type: ::Namespaces::UserNamespace.sti_name, owner: self),
          owned_groups.select(select).where(parent_id: nil)
        ]).to_sql
    end

    def namespace_union_for_reporter_developer_maintainer_owned(select = :id)
      ::Gitlab::SQL::Union.new(
        [
          ::Namespace.select(select).where(type: ::Namespaces::UserNamespace.sti_name, owner: self),
          reporter_developer_maintainer_owned_groups.select(select).where(parent_id: nil)
        ]).to_sql
    end

    def paid_in_current_license?
      return true unless License.current.exclude_guests_from_active_count?

      highest_role > ::Gitlab::Access::GUEST || elevated_members.any?
    end

    def available_minimal_access_groups
      return ::Group.none unless License.feature_available?(:minimal_access_role)
      return minimal_access_groups unless ::Gitlab::CurrentSettings.should_check_namespace_plan?

      minimal_access_groups.with_feature_available_in_plan(:minimal_access_role)
    end

    def perform_user_cap_check
      return unless self.class.user_cap_reached?
      return if active?

      run_after_commit do
        SetUserStatusBasedOnUserCapSettingWorker.perform_async(id)
      end
    end

    def email_changed_hook
      run_after_commit do
        if enterprise_user?
          ::Groups::EnterpriseUsers::DisassociateWorker.perform_async(id)
        end
      end
    end

    override :should_delay_delete?
    def should_delay_delete?(*args)
      super && !has_paid_namespace?(exclude_trials: true)
    end

    override :audit_lock_access
    def audit_lock_access(reason: nil)
      return if access_locked?

      if !reason && attempts_exceeded?
        reason = 'excessive failed login attempts'
      end

      ::Gitlab::Audit::Auditor.audit(
        name: 'user_access_locked',
        author: ::User.admin_bot,
        scope: self,
        target: self,
        message: ['User access locked', reason].compact.join(' - ')
      )
    end

    override :audit_unlock_access
    def audit_unlock_access(author: self)
      # We can't use access_locked? because it checks if locked_at <
      # User.unlock_in.ago. If we use access_locked? and the lock is already
      # expired the call to unlock_access! when a user tries to login will not
      # log an audit event as expected
      return unless locked_at.present?

      ::Gitlab::Audit::Auditor.audit(
        name: 'user_access_unlocked',
        author: author,
        scope: self,
        target: self,
        message: 'User access unlocked'
      )
    end
  end
end
