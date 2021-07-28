# frozen_string_literal: true

module EE
  # Group EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be included in the `Group` model
  module Group
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include TokenAuthenticatable
      include InsightsFeature
      include HasWiki
      include CanMoveRepositoryStorage

      add_authentication_token_field :saml_discovery_token, unique: false, token_generator: -> { Devise.friendly_token(8) }

      has_many :epics
      has_many :epic_boards, class_name: 'Boards::EpicBoard', inverse_of: :group
      has_many :iterations
      has_many :iterations_cadences, class_name: 'Iterations::Cadence'
      has_one :saml_provider
      has_many :scim_identities
      has_many :ip_restrictions, autosave: true
      has_many :protected_environments, inverse_of: :group
      has_one :insight, foreign_key: :namespace_id
      accepts_nested_attributes_for :insight, allow_destroy: true
      has_one :scim_oauth_access_token

      has_many :ldap_group_links, foreign_key: 'group_id', dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
      has_many :saml_group_links, foreign_key: 'group_id'
      has_many :hooks, class_name: 'GroupHook'

      has_many :allowed_email_domains, -> { order(id: :asc) }, autosave: true

      # We cannot simply set `has_many :audit_events, as: :entity, dependent: :destroy`
      # here since Group inherits from Namespace, the entity_type would be set to `Namespace`.
      has_many :audit_events, -> { where(entity_type: ::Group.name) }, foreign_key: 'entity_id'

      has_many :project_templates, through: :projects, foreign_key: 'custom_project_templates_group_id'

      has_many :managed_users, class_name: 'User', foreign_key: 'managing_group_id', inverse_of: :managing_group
      has_many :provisioned_user_details, class_name: 'UserDetail', foreign_key: 'provisioned_by_group_id', inverse_of: :provisioned_by_group
      has_many :provisioned_users, through: :provisioned_user_details, source: :user
      has_many :cycle_analytics_stages, class_name: 'Analytics::CycleAnalytics::GroupStage'
      has_many :value_streams, class_name: 'Analytics::CycleAnalytics::GroupValueStream'
      has_one :group_merge_request_approval_setting, inverse_of: :group

      has_one :deletion_schedule, class_name: 'GroupDeletionSchedule'
      delegate :deleting_user, :marked_for_deletion_on, to: :deletion_schedule, allow_nil: true
      delegate :enforced_group_managed_accounts?, :enforced_sso?, to: :saml_provider, allow_nil: true
      delegate :repository_read_only, :repository_read_only?, to: :namespace_settings, allow_nil: true

      has_one :group_wiki_repository
      has_many :repository_storage_moves, class_name: 'Groups::RepositoryStorageMove', inverse_of: :container

      has_many :epic_board_recent_visits, class_name: 'Boards::EpicBoardRecentVisit', inverse_of: :group

      belongs_to :file_template_project, class_name: "Project"

      belongs_to :push_rule, inverse_of: :group

      # Use +checked_file_template_project+ instead, which implements important
      # visibility checks
      private :file_template_project

      validates :repository_size_limit,
                numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }

      validates :max_personal_access_token_lifetime,
                allow_blank: true,
                numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 365 }

      validate :custom_project_templates_group_allowed, if: :custom_project_templates_group_id_changed?

      scope :aimed_for_deletion, ->(date) { joins(:deletion_schedule).where('group_deletion_schedules.marked_for_deletion_on <= ?', date) }
      scope :with_deletion_schedule, -> { preload(deletion_schedule: :deleting_user) }
      scope :with_deletion_schedule_only, -> { preload(:deletion_schedule) }

      scope :with_saml_provider, -> { preload(:saml_provider) }

      scope :where_group_links_with_provider, ->(provider) do
        joins(:ldap_group_links).where(ldap_group_links: { provider: provider })
      end

      scope :with_managed_accounts_enabled, -> do
        joins(:saml_provider).where(saml_providers:
          {
            enabled: true,
            enforced_sso: true,
            enforced_group_managed_accounts: true
          })
      end

      scope :with_no_pat_expiry_policy, -> { where(max_personal_access_token_lifetime: nil) }

      scope :with_project_templates, -> { where.not(custom_project_templates_group_id: nil) }

      scope :with_custom_file_templates, -> do
        preload(
          file_template_project: :route,
          projects: :route,
          shared_projects: :route
        ).where.not(file_template_project_id: nil)
      end

      scope :for_epics, ->(epics) do
        epics_query = epics.select(:group_id)
        joins("INNER JOIN (#{epics_query.to_sql}) as epics on epics.group_id = namespaces.id")
      end

      scope :user_is_member, -> (user) { id_in(user.authorized_groups(with_minimal_access: false)) }

      state_machine :ldap_sync_status, namespace: :ldap_sync, initial: :ready do
        state :ready
        state :started
        state :pending
        state :failed

        event :pending do
          transition [:ready, :failed] => :pending
        end

        event :start do
          transition [:ready, :pending, :failed] => :started
        end

        event :finish do
          transition started: :ready
        end

        event :fail do
          transition started: :failed
        end

        after_transition ready: :started do |group, _|
          group.ldap_sync_last_sync_at = DateTime.current
          group.save
        end

        after_transition started: :ready do |group, _|
          current_time = DateTime.current
          group.ldap_sync_last_update_at = current_time
          group.ldap_sync_last_successful_update_at = current_time
          group.ldap_sync_error = nil
          group.save
        end

        after_transition started: :failed do |group, _|
          group.ldap_sync_last_update_at = DateTime.current
          group.save
        end
      end
    end

    class_methods do
      def groups_user_can(groups, user, action, same_root: false)
        groups = ::Gitlab::GroupPlansPreloader.new.preload(groups)

        # if we are sure that all groups have the same root group, we can
        # preset root_ancestor for all of them to avoid an additional SQL query
        # done for each group permission check:
        # https://gitlab.com/gitlab-org/gitlab/issues/11539
        preset_root_ancestor_for(groups) if same_root

        DeclarativePolicy.user_scope do
          groups.select { |group| Ability.allowed?(user, action, group) }
        end
      end

      def groups_user_can_read_epics(groups, user, same_root: false)
        groups_user_can(groups, user, :read_epic, same_root: same_root)
      end
    end

    def ip_restriction_ranges
      return unless ip_restrictions.present?

      ip_restrictions.map(&:range).join(",")
    end

    def allowed_email_domains_list
      return if allowed_email_domains.empty?

      allowed_email_domains.domain_names.join(",")
    end

    def human_ldap_access
      ::Gitlab::Access.options_with_owner.key(ldap_access)
    end

    # NOTE: Backwards compatibility with old ldap situation
    def ldap_cn
      ldap_group_links.first.try(:cn)
    end

    def ldap_access
      ldap_group_links.first.try(:group_access)
    end

    override :ldap_synced?
    def ldap_synced?
      (::Gitlab.config.ldap.enabled && ldap_group_links.any?(&:active?)) || super
    end

    def mark_ldap_sync_as_failed(error_message, skip_validation: false)
      return false unless ldap_sync_started?

      error_message = ::Gitlab::UrlSanitizer.sanitize(error_message)

      if skip_validation
        # A group that does not validate cannot transition out of its
        # current state, so manually set the ldap_sync_status
        update_columns(ldap_sync_error: error_message,
                       ldap_sync_status: 'failed')
      else
        fail_ldap_sync
        update_column(:ldap_sync_error, error_message)
      end
    end

    # This token conveys that the anonymous user is allowed to know of the group
    # Used to avoid revealing that a group exists on a given path
    def saml_discovery_token
      ensure_saml_discovery_token!
    end

    def saml_enabled?
      return false unless saml_provider

      saml_provider.persisted? && saml_provider.enabled?
    end

    def saml_group_sync_available?
      feature_available?(:group_saml_group_sync) && root_ancestor.saml_enabled?
    end

    override :multiple_issue_boards_available?
    def multiple_issue_boards_available?
      feature_available?(:multiple_group_issue_boards)
    end

    def multiple_iteration_cadences_available?
      feature_available?(:multiple_iteration_cadences)
    end

    def group_project_template_available?
      feature_available?(:group_project_templates)
    end

    def scoped_variables_available?
      feature_available?(:group_scoped_ci_variables)
    end

    def actual_size_limit
      return ::Gitlab::CurrentSettings.repository_size_limit if repository_size_limit.nil?

      repository_size_limit
    end

    def first_non_empty_project
      projects.detect { |project| !project.empty_repo? }
    end

    def project_ids_with_security_reports
      all_projects.with_security_reports_stored.pluck_primary_key
    end

    def root_ancestor_ip_restrictions
      return ip_restrictions if parent_id.nil?

      root_ancestor.ip_restrictions
    end

    def root_ancestor_allowed_email_domains
      return allowed_email_domains if parent_id.nil?

      root_ancestor.allowed_email_domains
    end

    # Overrides a method defined in `::EE::Namespace`
    override :checked_file_template_project
    def checked_file_template_project(*args, &blk)
      project = file_template_project(*args, &blk)

      return unless project && (
          project_ids.include?(project.id) || shared_project_ids.include?(project.id))

      # The license check would normally be the cheapest to perform, so would
      # come first. In this case, the method is carefully designed to perform
      # no SQL at all, but `feature_available?` will cause an ApplicationSetting
      # to be created if it doesn't already exist! This is mostly a problem in
      # the specs, but best avoided in any case.
      return unless feature_available?(:custom_file_templates_for_namespace)

      project
    end

    override :billable_members_count
    def billable_members_count(requested_hosted_plan = nil)
      billable_ids = billed_user_ids(requested_hosted_plan)

      billable_ids[:user_ids].count
    end

    # For now, we are not billing for members with a Guest role for subscriptions
    # with a Gold/Ultimate plan. The other plans will treat Guest members as a regular member
    # for billing purposes.
    #
    # For the user_ids key, we are plucking the user_ids from the "Members" table in an array and
    # converting the array of user_ids to a Set which will have unique user_ids.
    def billed_user_ids(requested_hosted_plan = nil)
      exclude_guests = ([actual_plan_name, requested_hosted_plan] & [::Plan::GOLD, ::Plan::ULTIMATE]).any?

      exclude_guests ? billed_user_ids_excluding_guests : billed_user_ids_including_guests
    end

    override :supports_events?
    def supports_events?
      feature_available?(:epics)
    end

    def marked_for_deletion?
      marked_for_deletion_on.present? &&
        feature_available?(:adjourned_deletion_for_projects_and_groups)
    end

    def self_or_ancestor_marked_for_deletion
      return unless feature_available?(:adjourned_deletion_for_projects_and_groups)

      self_and_ancestors(hierarchy_order: :asc)
        .joins(:deletion_schedule).first
    end

    override :adjourned_deletion?
    def adjourned_deletion?
      feature_available?(:adjourned_deletion_for_projects_and_groups) &&
        ::Gitlab::CurrentSettings.deletion_adjourned_period > 0
    end

    def vulnerabilities
      ::Vulnerability.where(
        project: ::Project.for_group_and_its_subgroups(self).non_archived.without_deleted
      )
    end

    def vulnerability_scanners
      ::Vulnerabilities::Scanner.where(
        project: ::Project.for_group_and_its_subgroups(self).non_archived.without_deleted
      )
    end

    def vulnerability_historical_statistics
      ::Vulnerabilities::HistoricalStatistic
        .for_project(::Project.for_group_and_its_subgroups(self).non_archived.without_deleted)
    end

    def max_personal_access_token_lifetime_from_now
      if max_personal_access_token_lifetime.present?
        max_personal_access_token_lifetime.days.from_now
      else
        ::Gitlab::CurrentSettings.max_personal_access_token_lifetime_from_now
      end
    end

    def personal_access_token_expiration_policy_available?
      enforced_group_managed_accounts? && License.feature_available?(:personal_access_token_expiration_policy)
    end

    def update_personal_access_tokens_lifetime
      return unless max_personal_access_token_lifetime.present? && personal_access_token_expiration_policy_available?

      ::PersonalAccessTokens::Groups::UpdateLifetimeService.new(self).execute
    end

    def predefined_push_rule
      strong_memoize(:predefined_push_rule) do
        next push_rule if push_rule

        if has_parent?
          parent.predefined_push_rule
        else
          PushRule.global
        end
      end
    end

    def owners_emails
      owners.pluck(:email)
    end

    # this method will be delegated to namespace_settings, but as we need to wait till
    # all groups will have namespace_settings created via background migration,
    # we need to serve it from this class
    def prevent_forking_outside_group?
      return namespace_settings.prevent_forking_outside_group? if namespace_settings

      root_ancestor.saml_provider&.prohibited_outer_forks?
    end

    def minimal_access_role_allowed?
      feature_available?(:minimal_access_role) && !has_parent?
    end

    override :member?
    def member?(user, min_access_level = minimal_member_access_level)
      if min_access_level == ::Gitlab::Access::MINIMAL_ACCESS && minimal_access_role_allowed?
        all_group_members.find_by(user_id: user.id).present?
      else
        super
      end
    end

    def minimal_member_access_level
      minimal_access_role_allowed? ? ::Gitlab::Access::MINIMAL_ACCESS : ::Gitlab::Access::GUEST
    end

    override :access_level_roles
    def access_level_roles
      levels = ::GroupMember.access_level_roles
      return levels unless minimal_access_role_allowed?

      levels.merge(::Gitlab::Access::MINIMAL_ACCESS_HASH)
    end

    override :users_count
    def users_count
      return all_group_members.count if minimal_access_role_allowed?

      members.count
    end

    def releases_count
      ::Release.by_namespace_id(self_and_descendants.select(:id)).count
    end

    def releases_percentage
      calculate_sql = <<~SQL
      (
        COUNT(*) FILTER (WHERE EXISTS (SELECT 1 FROM releases WHERE releases.project_id = projects.id)) * 100.0 / GREATEST(COUNT(*), 1)
      )::integer AS releases_percentage
      SQL

      self.class.count_by_sql(
        ::Project.select(calculate_sql)
        .where(namespace_id: self_and_descendants.select(:id)).to_sql
      )
    end

    override :execute_hooks
    def execute_hooks(data, hooks_scope)
      super

      return unless feature_available?(:group_webhooks)

      self_and_ancestor_hooks = GroupHook.where(group_id: self_and_ancestors)
      self_and_ancestor_hooks.hooks_for(hooks_scope).each do |hook|
        hook.async_execute(data, hooks_scope.to_s)
      end
    end

    override :git_transfer_in_progress?
    def git_transfer_in_progress?
      reference_counter(type: ::Gitlab::GlRepository::WIKI).value > 0
    end

    def repository_storage
      group_wiki_repository&.shard_name || ::Repository.pick_storage_shard
    end

    def iteration_cadences_feature_flag_enabled?
      ::Feature.enabled?(:iteration_cadences, self, default_enabled: :yaml)
    end

    def user_cap_reached?(requested_hosted_plan = nil)
      return false unless ::Feature.enabled?(:saas_user_caps, self, default_enabled: :yaml)

      user_cap = root_ancestor.new_user_signups_cap
      return false unless user_cap

      user_cap <= billable_members_count(requested_hosted_plan)
    end

    private

    override :post_create_hook
    def post_create_hook
      super

      execute_subgroup_hooks(:create)
    end

    override :post_destroy_hook
    def post_destroy_hook
      super

      execute_subgroup_hooks(:destroy)
    end

    def execute_subgroup_hooks(event)
      return unless subgroup?
      return unless feature_available?(:group_webhooks)

      run_after_commit do
        data = ::Gitlab::HookData::SubgroupBuilder.new(self).build(event)
        # Imagine a case where a subgroup has a webhook with `subgroup_events` enabled.
        # When this subgroup is removed, there is no point in this subgroup's webhook itself being notified
        # that `self` was removed. Rather, we should only care about notifying its ancestors
        # and hence we need to trigger the hooks starting only from its `parent` group.
        parent.execute_hooks(data, :subgroup_hooks)
      end
    end

    def custom_project_templates_group_allowed
      return if custom_project_templates_group_id.blank?
      return if children.exists?(id: custom_project_templates_group_id)

      errors.add(:custom_project_templates_group_id, 'has to be a subgroup of the group')
    end

    def billed_user_ids_excluding_guests
      strong_memoize(:billed_user_ids_excluding_guests) do
        group_member_user_ids = billed_group_members.non_guests.distinct.pluck(:user_id)
        project_member_user_ids = billed_project_users(non_guests: true).distinct.pluck(:id)
        shared_group_user_ids = billed_shared_non_guests_group_members.non_guests.distinct.pluck(:user_id)
        shared_project_user_ids = billed_invited_non_guests_group_to_project_members.non_guests.distinct.pluck(:user_id)

        {
          user_ids: (group_member_user_ids + project_member_user_ids + shared_group_user_ids + shared_project_user_ids).to_set,
          group_member_user_ids: group_member_user_ids.to_set,
          project_member_user_ids: project_member_user_ids.to_set,
          shared_group_user_ids: shared_group_user_ids.to_set,
          shared_project_user_ids: shared_project_user_ids.to_set
        }
      end
    end

    def billed_user_ids_including_guests
      strong_memoize(:billed_user_ids_including_guests) do
        group_member_user_ids = billed_group_members.distinct.pluck(:user_id)
        project_member_user_ids = billed_project_users.distinct.pluck(:id)
        shared_group_user_ids = billed_shared_group_members.distinct.pluck(:user_id)
        shared_project_user_ids = billed_invited_group_to_project_members.distinct.pluck(:user_id)

        {
          user_ids: (group_member_user_ids + project_member_user_ids + shared_group_user_ids + shared_project_user_ids).to_set,
          group_member_user_ids: group_member_user_ids.to_set,
          project_member_user_ids: project_member_user_ids.to_set,
          shared_group_user_ids: shared_group_user_ids.to_set,
          shared_project_user_ids: shared_project_user_ids.to_set
        }
      end
    end

    # Members belonging directly to Group or its subgroups
    def billed_group_members
      ::GroupMember.active_without_invites_and_requests.where(
        source_id: self_and_descendants
      )
    end

    # Members belonging directly to Projects within Group or Projects within subgroups
    def billed_project_users(non_guests: false)
      members = ::ProjectMember.without_invites_and_requests

      members = members.non_guests if non_guests

      user_ids = members.where(
        source_id: ::Project.joins(:group).where(namespace: self_and_descendants)
      )
      .distinct
      .select(:user_id)

      ::User.with_state(:active).without_project_bot.where(id: user_ids)
    end

    # Members belonging to Groups invited to collaborate with Projects
    def billed_invited_group_to_project_members
      invited_or_shared_group_members(invited_groups_in_projects)
    end

    def billed_invited_non_guests_group_to_project_members
      invited_or_shared_group_members(invited_group_as_non_guests_in_projects)
    end

    def invited_group_as_non_guests_in_projects
      invited_groups_in_projects.merge(::ProjectGroupLink.non_guests)
    end

    def invited_groups_in_projects
      ::Group.joins(:project_group_links)
        .where(project_group_links: { project_id: all_projects })
    end

    # Members belonging to Groups invited to collaborate with Groups and Subgroups
    def billed_shared_group_members
      invited_or_shared_group_members(invited_group_in_groups)
    end

    def billed_shared_non_guests_group_members
      invited_or_shared_group_members(invited_non_guest_group_in_groups)
    end

    def invited_non_guest_group_in_groups
      invited_group_in_groups.merge(::GroupGroupLink.non_guests)
    end

    def invited_group_in_groups
      ::Group.joins(:shared_group_links)
        .where(group_group_links: { shared_group_id: ::Group.groups_including_descendants_by([self]) })
    end

    def invited_or_shared_group_members(groups)
      ::GroupMember.active_without_invites_and_requests.where(source_id: ::Gitlab::ObjectHierarchy.new(groups).base_and_ancestors)
    end

    override :_safe_read_repository_read_only_column
    def _safe_read_repository_read_only_column
      ::NamespaceSetting.where(namespace: self).pick(:repository_read_only)
    end

    override :_update_repository_read_only_column
    def _update_repository_read_only_column(value)
      settings = namespace_settings || create_namespace_settings

      settings.update_column(:repository_read_only, value)
    end
  end
end
