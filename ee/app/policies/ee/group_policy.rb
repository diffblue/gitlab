# frozen_string_literal: true

module EE
  module GroupPolicy
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include CrudPolicyHelpers

      condition(:group_member, scope: :subject) { @user && @user.is_a?(User) && @subject.member?(@user) }
      condition(:ldap_synced, scope: :subject) { @subject.ldap_synced? }
      condition(:saml_group_links_enabled, scope: :subject) do
        @subject.root_ancestor.saml_group_links_enabled?
      end

      condition(:epics_available, scope: :subject) { @subject.feature_available?(:epics) }
      condition(:iterations_available, scope: :subject) { @subject.feature_available?(:iterations) }
      condition(:subepics_available, scope: :subject) { @subject.feature_available?(:subepics) }
      condition(:external_audit_events_available, scope: :subject) do
        @subject.feature_available?(:external_audit_events)
      end
      condition(:contribution_analytics_available, scope: :subject) do
        @subject.feature_available?(:contribution_analytics)
      end

      condition(:group_analytics_dashboards_available, scope: :subject) do
        @subject.feature_available?(:group_level_analytics_dashboard)
      end

      condition(:cycle_analytics_available, scope: :subject) do
        @subject.feature_available?(:cycle_analytics_for_groups)
      end

      condition(:group_ci_cd_analytics_available, scope: :subject) do
        @subject.feature_available?(:group_ci_cd_analytics)
      end

      condition(:group_repository_analytics_available, scope: :subject) do
        @subject.feature_available?(:group_repository_analytics)
      end

      condition(:group_coverage_reports_available, scope: :subject) do
        @subject.feature_available?(:group_coverage_reports)
      end

      condition(:group_activity_analytics_available, scope: :subject) do
        @subject.feature_available?(:group_activity_analytics)
      end

      condition(:group_devops_adoption_available, scope: :subject) do
        @subject.feature_available?(:group_level_devops_adoption)
      end

      condition(:group_devops_adoption_enabled, scope: :global) do
        ::License.feature_available?(:group_level_devops_adoption)
      end

      condition(:dora4_analytics_available, scope: :subject) do
        @subject.feature_available?(:dora4_analytics)
      end

      condition(:group_membership_export_available, scope: :subject) do
        @subject.feature_available?(:export_user_permissions)
      end

      condition(:can_owners_manage_ldap, scope: :global) do
        ::Gitlab::CurrentSettings.allow_group_owners_to_manage_ldap?
      end

      condition(:memberships_locked_to_ldap, scope: :global) do
        ::Gitlab::CurrentSettings.lock_memberships_to_ldap?
      end

      condition(:memberships_locked_to_saml, scope: :global) do
        ::Gitlab::CurrentSettings.lock_memberships_to_saml
      end

      condition(:owners_bypass_ldap_lock) do
        ldap_lock_bypassable?
      end

      condition(:security_dashboard_enabled, scope: :subject) do
        @subject.feature_available?(:security_dashboard)
      end

      condition(:prevent_group_forking_available, scope: :subject) do
        @subject.feature_available?(:group_forking_protection)
      end

      condition(:needs_new_sso_session, scope: :subject) do
        ::Gitlab::Auth::GroupSaml::SsoEnforcer.group_access_restricted?(@subject, user: @user) && (@subject.private? || group_member?)
      end

      condition(:no_active_sso_session, scope: :subject) do
        ::Gitlab::Auth::GroupSaml::SessionEnforcer.new(@user, @subject).access_restricted?
      end

      condition(:ip_enforcement_prevents_access, scope: :subject) do
        !::Gitlab::IpRestriction::Enforcer.new(subject).allows_current_ip?
      end

      condition(:cluster_deployments_available, scope: :subject) do
        @subject.feature_available?(:cluster_deployments)
      end

      condition(:global_saml_enabled, scope: :global) do
        ::Gitlab::Auth::Saml::Config.enabled?
      end

      condition(:global_saml_group_sync_enabled, scope: :global) do
        ::Gitlab::Auth::Saml::Config.group_sync_enabled?
      end

      condition(:group_saml_globally_enabled, scope: :global) do
        ::Gitlab::Auth::GroupSaml::Config.enabled?
      end

      condition(:group_saml_enabled, scope: :subject) do
        @subject.group_saml_enabled?
      end

      condition(:group_saml_available, scope: :subject) do
        !@subject.subgroup? && @subject.feature_available?(:group_saml)
      end

      condition(:group_saml_group_sync_available, scope: :subject) do
        @subject.saml_group_sync_available?
      end

      condition(:commit_committer_check_available, scope: :subject) do
        @subject.feature_available?(:commit_committer_check)
      end

      condition(:commit_committer_name_check_available, scope: :subject) do
        @subject.feature_available?(:commit_committer_name_check)
      end

      condition(:reject_unsigned_commits_available, scope: :subject) do
        @subject.feature_available?(:reject_unsigned_commits)
      end

      condition(:reject_non_dco_commits_available, scope: :subject) do
        @subject.feature_available?(:reject_non_dco_commits)
      end

      condition(:push_rules_available, scope: :subject) do
        @subject.feature_available?(:push_rules)
      end

      condition(:group_merge_request_approval_settings_enabled, scope: :subject) do
        @subject.feature_available?(:merge_request_approvers) && @subject.root?
      end

      condition(:read_only, scope: :subject) { @subject.read_only? }

      condition(:eligible_for_trial, scope: :subject) { @subject.eligible_for_trial? }

      condition(:compliance_framework_available, scope: :subject) do
        @subject.feature_available?(:custom_compliance_frameworks)
      end

      condition(:group_level_compliance_pipeline_available, scope: :subject) do
        @subject.feature_available?(:evaluate_group_level_compliance_pipeline)
      end

      condition(:security_orchestration_policies_enabled, scope: :subject) do
        @subject.feature_available?(:security_orchestration_policies)
      end

      condition(:group_level_compliance_dashboard_enabled, scope: :subject) do
        @subject.feature_available?(:group_level_compliance_dashboard)
      end

      condition(:service_accounts_available, scope: :subject) do
        @subject.feature_available?(:service_accounts)
      end

      condition(:user_banned_from_namespace) do
        next unless @user.is_a?(User)

        root_namespace = @subject.root_ancestor
        next unless root_namespace.unique_project_download_limit_enabled?

        @user.banned_from_namespace?(root_namespace)
      end

      condition(:unique_project_download_limit_enabled) do
        @subject.unique_project_download_limit_enabled?
      end

      rule { owner & unique_project_download_limit_enabled }.policy do
        enable :ban_group_member
      end

      condition(:security_policy_project_available) do
        @subject.security_orchestration_policy_configuration.present?
      end

      condition(:can_commit_to_security_policy_project) do
        security_orchestration_policy_configuration = @subject.security_orchestration_policy_configuration

        next unless security_orchestration_policy_configuration

        Ability.allowed?(@user, :developer_access, security_orchestration_policy_configuration.security_policy_management_project)
      end

      rule { ~admin & user_banned_from_namespace }.policy do
        prevent :read_group
      end

      rule { public_group | logged_in_viewable }.policy do
        enable :read_wiki
        enable :download_wiki_code
      end

      rule { guest }.policy do
        enable :read_wiki
        enable :read_group_release_stats

        # Only used on specific scenario to filter out subgroup epics not visible
        # to user when showing parent group epics list
        enable :list_subgroup_epics
      end

      rule { reporter }.policy do
        enable :admin_issue_board_list
        enable :view_productivity_analytics
        enable :view_type_of_work_charts
        enable :download_wiki_code
      end

      rule { maintainer }.policy do
        enable :maintainer_access
        enable :admin_wiki
        enable :modify_product_analytics_settings
      end

      rule { auditor }.policy do
        enable :view_productivity_analytics
        enable :view_group_devops_adoption
        enable :read_group_repository_analytics
        enable :read_group_contribution_analytics
        enable :read_group_cycle_analytics
        enable :read_cluster # Deprecated as certificate-based cluster integration (`Clusters::Cluster`).
        enable :read_cluster_agent
        enable :read_dependency_proxy
        enable :read_wiki

        enable :read_group_all_available_runners
        enable :read_group_runners
      end

      rule { auditor & group_ci_cd_analytics_available }.policy do
        enable :view_group_ci_cd_analytics
        enable :read_group_release_stats
      end

      rule { group_level_compliance_dashboard_enabled & auditor }.policy do
        enable :read_group_compliance_dashboard
      end

      rule { owner }
        .enable :admin_protected_environment

      rule { can?(:owner_access) }.policy do
        enable :set_epic_created_at
        enable :set_epic_updated_at
      end

      rule { can?(:read_cluster) & cluster_deployments_available }
        .enable :read_cluster_environments

      rule { has_access & contribution_analytics_available }
        .enable :read_group_contribution_analytics

      rule { has_access & group_activity_analytics_available }
        .enable :read_group_activity_analytics

      rule { (admin | reporter | auditor) & dora4_analytics_available }
        .enable :read_dora4_analytics

      rule { reporter & group_repository_analytics_available }
        .enable :read_group_repository_analytics

      rule { reporter & group_coverage_reports_available }
        .enable :read_group_coverage_reports

      rule { reporter & group_analytics_dashboards_available }.policy do
        enable :read_group_analytics_dashboards
      end

      rule { reporter & cycle_analytics_available }.policy do
        enable :read_group_cycle_analytics, :create_group_stage, :read_group_stage, :update_group_stage, :delete_group_stage
      end

      rule { reporter & group_ci_cd_analytics_available }.policy do
        enable :view_group_ci_cd_analytics
      end

      rule { reporter & group_devops_adoption_enabled & group_devops_adoption_available }.policy do
        enable :manage_devops_adoption_namespaces
        enable :view_group_devops_adoption
      end

      rule { admin & group_devops_adoption_enabled }.policy do
        enable :manage_devops_adoption_namespaces
      end

      rule { owner & ~has_parent & prevent_group_forking_available }.policy do
        enable :change_prevent_group_forking
      end

      rule { can?(:read_group) & epics_available }.policy do
        enable :read_epic
        enable :read_epic_board
        enable :read_epic_board_list
      end

      rule { can?(:read_group) & iterations_available }.policy do
        enable :read_iteration
        enable :read_iteration_cadence
      end

      rule { reporter & iterations_available }.policy do
        enable :create_iteration
        enable :admin_iteration
        enable :create_iteration_cadence
        enable :admin_iteration_cadence
      end

      rule { (automation_bot | reporter) & iterations_available }.policy do
        enable :rollover_issues
      end

      rule { reporter & epics_available }.policy do
        enable :create_epic
        enable :admin_epic
        enable :update_epic
        enable :read_confidential_epic
        enable :admin_epic_board
        enable :admin_epic_board_list
      end

      rule { owner & epics_available }.enable :destroy_epic

      rule { ~can?(:read_cross_project) }.policy do
        prevent :read_group_contribution_analytics
        prevent :read_epic
        prevent :read_confidential_epic
        prevent :create_epic
        prevent :admin_epic
        prevent :update_epic
        prevent :destroy_epic
        prevent :admin_epic_board_list
      end

      rule { auditor }.policy do
        enable :read_group
        enable :read_group_security_dashboard
        enable :read_group_audit_events
        enable :read_billing
        enable :read_container_image
      end

      rule { group_saml_globally_enabled & group_saml_available & (admin | owner) }.enable :admin_group_saml

      rule { group_saml_group_sync_available & (admin | owner) }.policy do
        enable :admin_saml_group_links
      end

      rule { global_saml_enabled & global_saml_group_sync_enabled & (admin | owner) }.policy do
        enable :admin_saml_group_links
      end

      rule { admin | (can_owners_manage_ldap & owner) }.policy do
        enable :admin_ldap_group_links
        enable :admin_ldap_group_settings
      end

      rule { ldap_synced & ~owners_bypass_ldap_lock }.prevent :admin_group_member

      rule { ldap_synced & (admin | owner) }.enable :update_group_member

      rule { ldap_synced & (admin | (can_owners_manage_ldap & owner)) }.enable :override_group_member

      rule { memberships_locked_to_ldap & ~admin & ~owners_bypass_ldap_lock }.policy do
        prevent :admin_group_member
        prevent :update_group_member
        prevent :override_group_member
      end

      rule { owner & service_accounts_available }.policy do
        enable :admin_service_accounts
      end

      rule { memberships_locked_to_saml & saml_group_links_enabled & ~admin }.policy do
        prevent :admin_group_member
      end

      rule { developer }.policy do
        enable :create_wiki
        enable :admin_merge_request
        enable :read_group_audit_events
        enable :read_product_analytics
      end

      rule { security_orchestration_policies_enabled & can?(:developer_access) }.policy do
        enable :read_security_orchestration_policies
      end

      rule { security_orchestration_policies_enabled & auditor }.policy do
        enable :read_security_orchestration_policies
      end

      rule { security_orchestration_policies_enabled & can?(:owner_access) }.policy do
        enable :update_security_orchestration_policy_project
        enable :modify_security_policy
      end

      rule { security_orchestration_policies_enabled & security_policy_project_available & can_commit_to_security_policy_project }.policy do
        enable :modify_security_policy
      end

      rule { security_dashboard_enabled & developer }.policy do
        enable :read_group_security_dashboard
        enable :admin_vulnerability
        enable :read_vulnerability
      end

      rule { can?(:read_group_security_dashboard) }.policy do
        enable :create_vulnerability_export
        enable :read_security_resource
      end

      rule { admin | owner }.policy do
        enable :owner_access
        enable :read_billable_member
        enable :read_group_compliance_dashboard
        enable :read_group_credentials_inventory
        enable :admin_group_credentials_inventory
        enable :admin_ci_minutes
      end

      rule { (admin | owner) & group_merge_request_approval_settings_enabled }.policy do
        enable :admin_merge_request_approval_settings
      end

      rule { needs_new_sso_session }.policy do
        prevent :read_group
      end

      rule { ip_enforcement_prevents_access & ~owner & ~auditor }.policy do
        prevent :read_group
        prevent :read_milestone
        prevent(*create_read_update_admin_destroy(:package))
        prevent :read_dependency_proxy
        prevent :admin_dependency_proxy
      end

      rule { owner & group_saml_enabled }.policy do
        enable :read_group_saml_identity
      end

      rule { ~(admin | allow_to_manage_default_branch_protection) }.policy do
        prevent :update_default_branch_protection
      end

      desc "Group has wiki disabled"
      condition(:wiki_disabled, score: 32) do
        !@subject.licensed_feature_available?(:group_wikis) || !@subject.feature_available?(:wiki, @user)
      end

      rule { wiki_disabled }.policy do
        prevent(*create_read_update_admin_destroy(:wiki))
        prevent(:download_wiki_code)
      end

      rule { admin | maintainer }.enable :change_commit_committer_check

      rule { admin | maintainer }.enable :change_commit_committer_name_check

      rule { commit_committer_check_available }.policy do
        enable :read_commit_committer_check
      end

      rule { ~commit_committer_check_available }.policy do
        prevent :change_commit_committer_check
      end

      rule { commit_committer_name_check_available }.policy do
        enable :read_commit_committer_name_check
      end

      rule { ~commit_committer_name_check_available }.policy do
        prevent :change_commit_committer_name_check
      end

      rule { admin | maintainer }.enable :change_reject_unsigned_commits

      rule { reject_unsigned_commits_available }.enable :read_reject_unsigned_commits

      rule { ~reject_unsigned_commits_available }.prevent :change_reject_unsigned_commits

      rule { admin | maintainer }.enable :change_reject_non_dco_commits

      rule { reject_non_dco_commits_available }.enable :read_reject_non_dco_commits

      rule { ~reject_non_dco_commits_available }.prevent :change_reject_non_dco_commits

      rule { can?(:maintainer_access) & push_rules_available }.enable :change_push_rules

      rule { admin & is_gitlab_com }.enable :update_subscription_limit

      rule { maintainer & eligible_for_trial }.enable :start_trial

      rule { read_only }.policy do
        prevent :create_epic
        prevent :update_epic
        prevent :admin_pipeline
        prevent :admin_group_runners
        prevent :register_group_runners
        prevent :add_cluster
        prevent :create_cluster
        prevent :update_cluster
        prevent :admin_cluster
        prevent :create_deploy_token
        prevent :create_subgroup
        prevent :create_package
      end

      rule { can?(:owner_access) & group_membership_export_available }.enable :export_group_memberships
      rule { can?(:owner_access) & compliance_framework_available }.enable :admin_compliance_framework
      rule { can?(:owner_access) & group_level_compliance_pipeline_available }.enable :admin_compliance_pipeline_configuration
      rule { can?(:owner_access) & external_audit_events_available }.policy do
        enable :admin_external_audit_events
      end

      # Special case to allow support bot assigning service desk
      # issues to epics in private groups using quick actions
      rule { support_bot & has_project_with_service_desk_enabled }.policy do
        enable :read_epic
        enable :read_epic_iid
      end
    end

    override :lookup_access_level!
    def lookup_access_level!(for_any_session: false)
      if for_any_session
        return ::GroupMember::NO_ACCESS if no_active_sso_session?
      elsif needs_new_sso_session?
        return ::GroupMember::NO_ACCESS
      end

      super
    end

    override :can_read_group_member?
    def can_read_group_member?
      return true if user&.can_read_all_resources?

      super
    end

    def ldap_lock_bypassable?
      return false unless ::Feature.enabled?(:ldap_settings_unlock_groups_by_owners)
      return false unless ::Gitlab::CurrentSettings.allow_group_owners_to_manage_ldap?

      !!subject.unlock_membership_to_ldap? && subject.owned_by?(user)
    end

    # Available in Core for self-managed but only paid, non-trial for .com to prevent abuse
    override :resource_access_token_create_feature_available?
    def resource_access_token_create_feature_available?
      return false unless resource_access_token_feature_available?
      return super unless ::Gitlab.com?

      group.feature_available_non_trial?(:resource_access_token)
    end

    override :resource_access_token_feature_available?
    def resource_access_token_feature_available?
      return false if ::Gitlab::CurrentSettings.personal_access_tokens_disabled?

      super
    end
  end
end
