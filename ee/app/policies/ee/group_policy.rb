# frozen_string_literal: true

module EE
  module GroupPolicy
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include CrudPolicyHelpers

      with_scope :subject
      condition(:ldap_synced) { @subject.ldap_synced? }
      condition(:epics_available) { @subject.feature_available?(:epics) }
      condition(:iterations_available) { @subject.feature_available?(:iterations) }
      condition(:subepics_available) { @subject.feature_available?(:subepics) }
      condition(:contribution_analytics_available) do
        @subject.feature_available?(:contribution_analytics)
      end

      condition(:cycle_analytics_available) do
        @subject.feature_available?(:cycle_analytics_for_groups)
      end

      condition(:group_ci_cd_analytics_available) do
        @subject.feature_available?(:group_ci_cd_analytics)
      end

      condition(:group_merge_request_analytics_available) do
        @subject.feature_available?(:group_merge_request_analytics)
      end

      condition(:group_repository_analytics_available) do
        @subject.feature_available?(:group_repository_analytics)
      end

      condition(:group_coverage_reports_available) do
        @subject.feature_available?(:group_coverage_reports)
      end

      condition(:group_activity_analytics_available) do
        @subject.feature_available?(:group_activity_analytics)
      end

      condition(:group_devops_adoption_available) do
        @subject.feature_available?(:group_level_devops_adoption)
      end

      condition(:group_devops_adoption_enabled) do
        ::License.feature_available?(:group_level_devops_adoption)
      end

      condition(:dora4_analytics_available) do
        @subject.feature_available?(:dora4_analytics)
      end

      condition(:group_membership_export_available) do
        @subject.feature_available?(:export_user_permissions) && ::Feature.enabled?(:ff_group_membership_export, @subject, default_enabled: :yaml)
      end

      condition(:can_owners_manage_ldap, scope: :global) do
        ::Gitlab::CurrentSettings.allow_group_owners_to_manage_ldap?
      end

      condition(:memberships_locked_to_ldap, scope: :global) do
        ::Gitlab::CurrentSettings.lock_memberships_to_ldap?
      end

      condition(:owners_bypass_ldap_lock) do
        ldap_lock_bypassable?
      end

      condition(:security_dashboard_enabled) do
        @subject.feature_available?(:security_dashboard)
      end

      condition(:prevent_group_forking_available) do
        @subject.feature_available?(:group_forking_protection)
      end

      condition(:needs_new_sso_session) do
        sso_enforcement_prevents_access?
      end

      condition(:no_active_sso_session) do
        sso_session_prevents_access?
      end

      condition(:ip_enforcement_prevents_access) do
        !::Gitlab::IpRestriction::Enforcer.new(subject).allows_current_ip?
      end

      condition(:cluster_deployments_available) do
        @subject.feature_available?(:cluster_deployments)
      end

      condition(:group_saml_config_enabled, scope: :global) do
        ::Gitlab::Auth::GroupSaml::Config.enabled?
      end

      condition(:group_saml_available, scope: :subject) do
        !@subject.subgroup? && @subject.feature_available?(:group_saml)
      end

      condition(:group_saml_enabled, scope: :subject) do
        @subject.saml_enabled?
      end

      condition(:group_saml_group_sync_available, scope: :subject) do
        @subject.saml_group_sync_available?
      end

      condition(:commit_committer_check_available) do
        @subject.feature_available?(:commit_committer_check)
      end

      condition(:reject_unsigned_commits_available) do
        @subject.feature_available?(:reject_unsigned_commits)
      end

      condition(:push_rules_available) do
        @subject.feature_available?(:push_rules)
      end

      condition(:group_merge_request_approval_settings_enabled) do
        @subject.feature_available?(:group_merge_request_approval_settings) && @subject.root?
      end

      condition(:over_storage_limit, scope: :subject) { @subject.over_storage_limit? }

      condition(:eligible_for_trial, scope: :subject) { @subject.eligible_for_trial? }

      condition(:compliance_framework_available) do
        @subject.feature_available?(:custom_compliance_frameworks)
      end

      condition(:group_level_compliance_pipeline_available) do
        @subject.feature_available?(:evaluate_group_level_compliance_pipeline)
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
        enable :admin_protected_environment
      end

      rule { owner | admin }.policy do
        enable :owner_access
      end

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

      rule { reporter & dora4_analytics_available }
        .enable :read_dora4_analytics

      rule { reporter & group_repository_analytics_available }
        .enable :read_group_repository_analytics

      rule { reporter & group_coverage_reports_available }
        .enable :read_group_coverage_reports

      rule { reporter & group_merge_request_analytics_available }
        .enable :read_group_merge_request_analytics

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

      rule { developer & iterations_available }.policy do
        enable :create_iteration
        enable :admin_iteration
        enable :create_iteration_cadence
        enable :admin_iteration_cadence
      end

      rule { (automation_bot | developer) & iterations_available }.policy do
        enable :rollover_issues
      end

      rule { reporter & epics_available }.policy do
        enable :create_epic
        enable :admin_epic
        enable :update_epic
        enable :read_confidential_epic
        enable :destroy_epic_link
        enable :admin_epic_board
        enable :admin_epic_board_list
      end

      rule { reporter & subepics_available }.policy do
        enable :admin_epic_link
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
      end

      rule { group_saml_config_enabled & group_saml_available & (admin | owner) }.enable :admin_group_saml

      rule { group_saml_config_enabled & group_saml_group_sync_available & (admin | owner) }.policy do
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

      rule { developer }.policy do
        enable :create_wiki
        enable :admin_merge_request
        enable :read_ci_minutes_quota
        enable :read_group_audit_events
      end

      rule { security_dashboard_enabled & developer }.policy do
        enable :read_group_security_dashboard
        enable :admin_vulnerability
      end

      rule { can?(:read_group_security_dashboard) }.policy do
        enable :create_vulnerability_export
        enable :read_security_resource
      end

      rule { admin | owner }.policy do
        enable :read_group_compliance_dashboard
        enable :read_group_credentials_inventory
        enable :admin_group_credentials_inventory
      end

      rule { (admin | owner) & group_merge_request_approval_settings_enabled }.policy do
        enable :admin_merge_request_approval_settings
      end

      rule { needs_new_sso_session }.policy do
        prevent :read_group
      end

      rule { ip_enforcement_prevents_access & ~owner & ~auditor }.policy do
        prevent :read_group
      end

      rule { owner & group_saml_enabled }.policy do
        enable :read_group_saml_identity
      end

      rule { ~(admin | allow_to_manage_default_branch_protection) }.policy do
        prevent :update_default_branch_protection
      end

      desc "Group has wiki disabled"
      condition(:wiki_disabled, score: 32) { !@subject.feature_available?(:group_wikis) }

      rule { wiki_disabled }.policy do
        prevent(*create_read_update_admin_destroy(:wiki))
        prevent(:download_wiki_code)
      end

      rule { admin | maintainer }.enable :change_commit_committer_check

      rule { commit_committer_check_available }.policy do
        enable :read_commit_committer_check
      end

      rule { ~commit_committer_check_available }.policy do
        prevent :change_commit_committer_check
      end

      rule { admin | maintainer }.enable :change_reject_unsigned_commits

      rule { reject_unsigned_commits_available }.enable :read_reject_unsigned_commits

      rule { ~reject_unsigned_commits_available }.prevent :change_reject_unsigned_commits

      rule { can?(:maintainer_access) & push_rules_available }.enable :change_push_rules

      rule { admin & is_gitlab_com }.enable :update_subscription_limit

      rule { maintainer & eligible_for_trial }.enable :start_trial

      rule { over_storage_limit }.policy do
        prevent :create_projects
        prevent :create_epic
        prevent :update_epic
        prevent :admin_milestone
        prevent :upload_file
        prevent :admin_label
        prevent :admin_issue_board_list
        prevent :admin_issue
        prevent :admin_pipeline
        prevent :add_cluster
        prevent :create_cluster
        prevent :update_cluster
        prevent :admin_cluster
        prevent :admin_group_member
        prevent :create_deploy_token
        prevent :create_subgroup
      end

      rule { can?(:owner_access) & group_membership_export_available }.enable :export_group_memberships
      rule { can?(:owner_access) & compliance_framework_available }.enable :admin_compliance_framework
      rule { can?(:owner_access) & group_level_compliance_pipeline_available }.enable :admin_compliance_pipeline_configuration
    end

    override :lookup_access_level!
    def lookup_access_level!(for_any_session: false)
      if for_any_session
        return ::GroupMember::NO_ACCESS if no_active_sso_session?
      else
        return ::GroupMember::NO_ACCESS if needs_new_sso_session?
      end

      super
    end

    def ldap_lock_bypassable?
      return false unless ::Feature.enabled?(:ldap_settings_unlock_groups_by_owners)
      return false unless ::Gitlab::CurrentSettings.allow_group_owners_to_manage_ldap?

      !!subject.unlock_membership_to_ldap? && subject.owned_by?(user)
    end

    def sso_enforcement_prevents_access?
      return false unless subject.persisted?
      return false if user&.admin?
      return false if user&.auditor?

      ::Gitlab::Auth::GroupSaml::SsoEnforcer.group_access_restricted?(subject, user: user)
    end

    def sso_session_prevents_access?
      return false unless subject.persisted?
      return false if user&.auditor? || user&.can_read_all_resources?

      ::Gitlab::Auth::GroupSaml::SessionEnforcer.new(user, subject).access_restricted?
    end

    # Available in Core for self-managed but only paid, non-trial for .com to prevent abuse
    override :resource_access_token_feature_available?
    def resource_access_token_feature_available?
      return super unless ::Gitlab.com?

      group.feature_available_non_trial?(:resource_access_token)
    end
  end
end
