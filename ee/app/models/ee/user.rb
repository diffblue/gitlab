# frozen_string_literal: true

module EE
  # User EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `User` model
  module User
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    include AuditorUserHelper

    DEFAULT_ROADMAP_LAYOUT = 'months'
    DEFAULT_GROUP_VIEW = 'details'
    MAX_USERNAME_SUGGESTION_ATTEMPTS = 15

    prepended do
      include UsageStatistics

      EMAIL_OPT_IN_SOURCE_ID_GITLAB_COM = 1

      # We aren't using the `auditor?` method for the `if` condition here
      # because `auditor?` returns `false` when the `auditor` column is `true`
      # and the auditor add-on absent. We want to run this validation
      # regardless of the add-on's presence, so we need to check the `auditor`
      # column directly.
      validate :auditor_requires_license_add_on, if: :auditor
      validate :cannot_be_admin_and_auditor

      after_create :perform_user_cap_check

      delegate :shared_runners_minutes_limit, :shared_runners_minutes_limit=,
               :extra_shared_runners_minutes_limit, :extra_shared_runners_minutes_limit=,
               to: :namespace
      delegate :provisioned_by_group, :provisioned_by_group=,
               :provisioned_by_group_id, :provisioned_by_group_id=,
               to: :user_detail, allow_nil: true

      has_many :epics,                    foreign_key: :author_id
      has_many :requirements,             foreign_key: :author_id, inverse_of: :author, class_name: 'RequirementsManagement::Requirement'
      has_many :test_reports,             foreign_key: :author_id, inverse_of: :author, class_name: 'RequirementsManagement::TestReport'
      has_many :assigned_epics,           foreign_key: :assignee_id, class_name: "Epic"
      has_many :path_locks,               dependent: :destroy # rubocop: disable Cop/ActiveRecordDependent
      has_many :vulnerability_feedback, foreign_key: :author_id, class_name: 'Vulnerabilities::Feedback'
      has_many :commented_vulnerability_feedback, foreign_key: :comment_author_id, class_name: 'Vulnerabilities::Feedback'
      has_many :boards_epic_user_preferences, class_name: 'Boards::EpicUserPreference', inverse_of: :user
      has_many :epic_board_recent_visits, class_name: 'Boards::EpicBoardRecentVisit', inverse_of: :user

      has_many :approvals,                dependent: :destroy # rubocop: disable Cop/ActiveRecordDependent
      has_many :approvers,                dependent: :destroy # rubocop: disable Cop/ActiveRecordDependent

      has_many :minimal_access_group_members, -> { where(access_level: [::Gitlab::Access::MINIMAL_ACCESS]) }, class_name: 'GroupMember'
      has_many :minimal_access_groups, through: :minimal_access_group_members, source: :group

      has_many :users_ops_dashboard_projects
      has_many :ops_dashboard_projects, through: :users_ops_dashboard_projects, source: :project
      has_many :users_security_dashboard_projects
      has_many :security_dashboard_projects, through: :users_security_dashboard_projects, source: :project

      has_many :group_saml_identities, -> { where.not(saml_provider_id: nil) }, class_name: "::Identity"

      # Protected Branch Access
      has_many :protected_branch_merge_access_levels, dependent: :destroy, class_name: "::ProtectedBranch::MergeAccessLevel" # rubocop:disable Cop/ActiveRecordDependent
      has_many :protected_branch_push_access_levels, dependent: :destroy, class_name: "::ProtectedBranch::PushAccessLevel" # rubocop:disable Cop/ActiveRecordDependent
      has_many :protected_branch_unprotect_access_levels, dependent: :destroy, class_name: "::ProtectedBranch::UnprotectAccessLevel" # rubocop:disable Cop/ActiveRecordDependent

      has_many :smartcard_identities
      has_many :scim_identities

      has_many :board_preferences, class_name: 'BoardUserPreference', inverse_of: :user

      belongs_to :managing_group, class_name: 'Group', optional: true, inverse_of: :managed_users

      has_many :user_permission_export_uploads

      has_many :oncall_participants, class_name: 'IncidentManagement::OncallParticipant', inverse_of: :user
      has_many :oncall_rotations, class_name: 'IncidentManagement::OncallRotation', through: :oncall_participants, source: :rotation
      has_many :oncall_schedules, class_name: 'IncidentManagement::OncallSchedule', through: :oncall_rotations, source: :schedule

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
          .merge(::Member.non_guests)

        where('EXISTS (?)', subquery)
      end

      scope :subscribed_for_admin_email, -> { where(admin_email_unsubscribed_at: nil) }
      scope :ldap, -> { joins(:identities).where('identities.provider LIKE ?', 'ldap%') }
      scope :with_provider, ->(provider) do
        joins(:identities).where(identities: { provider: provider })
      end

      scope :with_invalid_expires_at_tokens, ->(expiration_date) do
        where(id: ::PersonalAccessToken.with_invalid_expires_at(expiration_date).select(:user_id))
      end

      accepts_nested_attributes_for :namespace

      enum roadmap_layout: { weeks: 1, months: 4, quarters: 12 }

      # User's Group preference
      # Note: When adding an option, it's value MUST equal to the last value + 1.
      enum group_view: { details: 1, security_dashboard: 2 }, _prefix: true
      scope :group_view_details, -> { where('group_view = ? OR group_view IS NULL', group_view[:details]) }
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

      def non_ldap
        joins('LEFT JOIN identities ON identities.user_id = users.id')
          .where('identities.provider IS NULL OR identities.provider NOT LIKE ?', 'ldap%')
      end

      def find_by_smartcard_identity(certificate_subject, certificate_issuer)
        joins(:smartcard_identities)
          .find_by(smartcard_identities: { subject: certificate_subject, issuer: certificate_issuer })
      end

      def username_suggestion(base_name)
        suffix = nil
        base_name = base_name.parameterize(separator: '_')
        MAX_USERNAME_SUGGESTION_ATTEMPTS.times do |attempt|
          username = "#{base_name}#{suffix}"
          return username unless ::Namespace.find_by_path_or_name(username)

          suffix = attempt + 1
        end

        ''
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

    def available_subgroups_with_custom_project_templates(group_id = nil)
      found_groups = GroupsWithTemplatesFinder.new(group_id).execute

      GroupsFinder.new(self, min_access_level: ::Gitlab::Access::DEVELOPER)
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
    # currently on a paid plan
    def has_paid_namespace?
      ::Namespace
        .from("(#{namespace_union_for_reporter_developer_maintainer_owned}) #{::Namespace.table_name}")
        .include_gitlab_subscription
        .where(gitlab_subscriptions: { hosted_plan: ::Plan.where(name: ::Plan::PAID_HOSTED_PLANS) })
        .any?
    end

    # Returns true if the user is an Owner on any namespace currently on
    # a paid plan
    def owns_paid_namespace?(plans: ::Plan::PAID_HOSTED_PLANS)
      ::Namespace
        .from("(#{namespace_union_for_owned}) #{::Namespace.table_name}")
        .include_gitlab_subscription
        .where(gitlab_subscriptions: { hosted_plan: ::Plan.where(name: plans) })
        .any?
    end

    def manageable_groups_eligible_for_trial
      manageable_groups.eligible_for_trial.order(:name)
    end

    override :has_current_license?
    def has_current_license?
      License.current.present?
    end

    def using_license_seat?
      active? &&
      !internal? &&
      !project_bot? &&
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

    def gitlab_employee?
      strong_memoize(:gitlab_employee) do
        ::Gitlab.com? && gitlab_team_member?
      end
    end

    def gitlab_team_member?
      strong_memoize(:gitlab_team_member) do
        ::Gitlab::Com.gitlab_com_group_member?(id) && human?
      end
    end

    def gitlab_service_user?
      strong_memoize(:gitlab_service_user) do
        service_user? && ::Gitlab::Com.gitlab_com_group_member?(id)
      end
    end

    def gitlab_bot?
      strong_memoize(:gitlab_bot) do
        bot? && ::Gitlab::Com.gitlab_com_group_member_id?(id)
      end
    end

    def security_dashboard
      InstanceSecurityDashboard.new(self)
    end

    def owns_upgradeable_namespace?
      !owns_paid_namespace?(plans: [::Plan::GOLD, ::Plan::ULTIMATE]) &&
        owns_paid_namespace?(plans: [::Plan::BRONZE, ::Plan::SILVER, ::Plan::PREMIUM])
    end

    # Returns the groups a user has access to, either through a membership or a project authorization
    override :authorized_groups
    def authorized_groups(with_minimal_access: true)
      return super() unless with_minimal_access

      ::Group.unscoped do
        ::Group.from_union([
          super(),
          available_minimal_access_groups
        ])
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

    protected

    override :password_required?
    def password_required?(*)
      return false if group_managed_account?

      super
    end

    private

    def created_after_credit_card_release_day?(project)
      created_at >= ::Users::CreditCardValidation::RELEASE_DAY ||
        ::Feature.enabled?(:ci_require_credit_card_for_old_users, project, default_enabled: :yaml)
    end

    def has_valid_credit_card?
      credit_card_validated_at.present?
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
      if root_namespace.free_plan?
        ::Feature.enabled?(:ci_require_credit_card_on_free_plan, project, default_enabled: :yaml)
      elsif root_namespace.trial?
        ::Feature.enabled?(:ci_require_credit_card_on_trial_plan, project, default_enabled: :yaml)
      else
        false
      end
    end

    def namespace_union_for_owned(select = :id)
      ::Gitlab::SQL::Union.new([
        ::Namespace.select(select).where(type: nil, owner: self),
        owned_groups.select(select).where(parent_id: nil)
      ]).to_sql
    end

    def namespace_union_for_reporter_developer_maintainer_owned(select = :id)
      ::Gitlab::SQL::Union.new([
        ::Namespace.select(select).where(type: nil, owner: self),
        reporter_developer_maintainer_owned_groups.select(select).where(parent_id: nil)
      ]).to_sql
    end

    def paid_in_current_license?
      return true unless License.current.exclude_guests_from_active_count?

      highest_role > ::Gitlab::Access::GUEST
    end

    def available_minimal_access_groups
      return ::Group.none unless License.feature_available?(:minimal_access_role)
      return minimal_access_groups unless ::Gitlab::CurrentSettings.should_check_namespace_plan?

      minimal_access_groups.with_feature_available_in_plan(:minimal_access_role)
    end

    def perform_user_cap_check
      return unless ::Gitlab::CurrentSettings.should_apply_user_signup_cap?

      run_after_commit do
        SetUserStatusBasedOnUserCapSettingWorker.perform_async(id)
      end
    end
  end
end
