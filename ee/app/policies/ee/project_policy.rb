# frozen_string_literal: true

module EE
  module ProjectPolicy
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include ReadonlyAbilities

      with_scope :subject
      condition(:auto_fix_enabled) { @subject.security_setting&.auto_fix_enabled? }

      with_scope :subject
      condition(:repository_mirrors_enabled) { @subject.feature_available?(:repository_mirrors) }

      with_scope :subject
      condition(:iterations_available) { @subject.group&.licensed_feature_available?(:iterations) }

      with_scope :subject
      condition(:requirements_available) { @subject.feature_available?(:requirements) & access_allowed_to?(:requirements) }

      with_scope :subject
      condition(:quality_management_available) { @subject.feature_available?(:quality_management) }

      condition(:compliance_framework_available) { @subject.feature_available?(:compliance_framework, @user) }

      with_scope :global
      condition(:is_development) { Rails.env.development? }

      with_scope :global
      condition(:locked_approvers_rules) do
        !@user.can_admin_all_resources? &&
          License.feature_available?(:admin_merge_request_approvers_rules) &&
          ::Gitlab::CurrentSettings.disable_overriding_approvers_per_merge_request
      end

      condition(:group_merge_request_approval_settings_enabled) do
        @subject.feature_available?(:merge_request_approvers)
      end

      with_scope :global
      condition(:locked_merge_request_author_setting) do
        License.feature_available?(:admin_merge_request_approvers_rules) &&
          ::Gitlab::CurrentSettings.prevent_merge_requests_author_approval
      end

      with_scope :global
      condition(:locked_merge_request_committer_setting) do
        License.feature_available?(:admin_merge_request_approvers_rules) &&
          ::Gitlab::CurrentSettings.prevent_merge_requests_committers_approval
      end

      with_scope :subject
      condition(:dora4_analytics_available) do
        @subject.feature_available?(:dora4_analytics)
      end

      condition(:project_merge_request_analytics_available) do
        @subject.feature_available?(:project_merge_request_analytics)
      end

      with_scope :subject
      condition(:group_push_rules_enabled) do
        @subject.group && @subject.group.licensed_feature_available?(:push_rules)
      end

      with_scope :subject
      condition(:group_push_rule_present) do
        group_push_rules_enabled? && subject.group.push_rule
      end

      with_scope :subject
      condition(:commit_committer_check_available) do
        @subject.feature_available?(:commit_committer_check)
      end

      with_scope :subject
      condition(:commit_committer_name_check_available) do
        @subject.feature_available?(:commit_committer_name_check)
      end

      with_scope :subject
      condition(:reject_unsigned_commits_available) do
        @subject.feature_available?(:reject_unsigned_commits)
      end

      with_scope :subject
      condition(:reject_non_dco_commits_available) do
        @subject.feature_available?(:reject_non_dco_commits)
      end

      with_scope :subject
      condition(:security_orchestration_policies_enabled) do
        @subject.feature_available?(:security_orchestration_policies)
      end

      with_scope :subject
      condition(:security_dashboard_enabled) do
        @subject.feature_available?(:security_dashboard)
      end

      with_scope :subject
      condition(:coverage_fuzzing_enabled) do
        @subject.feature_available?(:coverage_fuzzing)
      end

      with_scope :subject
      condition(:on_demand_scans_enabled) do
        @subject.feature_available?(:security_on_demand_scans)
      end

      with_scope :subject
      condition(:license_scanning_enabled) do
        @subject.feature_available?(:license_scanning)
      end

      with_scope :subject
      condition(:dependency_scanning_enabled) do
        @subject.feature_available?(:dependency_scanning)
      end

      with_scope :subject
      condition(:code_review_analytics_enabled) do
        @subject.feature_available?(:code_review_analytics, @user)
      end

      with_scope :subject
      condition(:issue_analytics_enabled) do
        @subject.feature_available?(:issues_analytics, @user)
      end

      with_scope :subject
      condition(:combined_project_analytics_dashboards_enabled) do
        @subject.feature_available?(:combined_project_analytics_dashboards, @user)
      end

      condition(:status_page_available) do
        @subject.feature_available?(:status_page, @user)
      end

      condition(:read_only, scope: :subject) do
        @subject.root_namespace.read_only?
      end

      with_scope :subject
      condition(:feature_flags_related_issues_disabled) do
        !@subject.feature_available?(:feature_flags_related_issues)
      end

      with_scope :subject
      condition(:oncall_schedules_available) do
        ::Gitlab::IncidentManagement.oncall_schedules_available?(@subject)
      end

      with_scope :subject
      condition(:escalation_policies_available) do
        ::Gitlab::IncidentManagement.escalation_policies_available?(@subject)
      end

      with_scope :subject
      condition(:hidden) do
        @subject.hidden?
      end

      with_scope :subject
      condition(:membership_locked_via_parent_group) do
        @subject.group && (
          @subject.group.membership_lock? ||
          ::Gitlab::CurrentSettings.lock_memberships_to_ldap? ||
          ::Gitlab::CurrentSettings.lock_memberships_to_saml)
      end

      with_scope :subject
      condition(:security_policy_project_available) do
        @subject.security_orchestration_policy_configuration.present?
      end

      with_scope :subject
      condition(:can_commit_to_security_policy_project) do
        security_orchestration_policy_configuration = @subject.security_orchestration_policy_configuration

        next unless security_orchestration_policy_configuration

        Ability.allowed?(@user, :developer_access, security_orchestration_policy_configuration.security_policy_management_project)
      end

      with_scope :subject
      condition(:okrs_enabled) do
        @subject.okrs_mvc_feature_flag_enabled? && @subject.feature_available?(:okrs)
      end

      condition(:user_banned_from_namespace) do
        next unless @user.is_a?(User)

        root_namespace = @subject.root_ancestor
        next unless root_namespace.group_namespace? && root_namespace.unique_project_download_limit_enabled?

        @user.banned_from_namespace?(root_namespace)
      end

      rule { membership_locked_via_parent_group }.policy do
        prevent :import_project_members_from_another_project
      end

      condition(:custom_roles_allowed) do
        @subject.custom_roles_enabled?
      end

      desc "Custom role on project that enables read code"
      condition(:role_enables_read_code) do
        next unless @user.is_a?(User)

        @user.read_code_for?(project)
      end

      with_scope :subject
      condition(:suggested_reviewers_available) do
        @subject.can_suggest_reviewers?
      end

      rule { visual_review_bot }.policy do
        prevent :read_note
        enable :create_note
      end

      rule { license_block }.policy do
        prevent :create_issue
        prevent :create_merge_request_in
        prevent :create_merge_request_from
        prevent :push_code
      end

      rule { analytics_disabled }.policy do
        prevent(:read_project_merge_request_analytics)
        prevent(:read_code_review_analytics)
        prevent(:read_issue_analytics)
      end

      rule { feature_flags_related_issues_disabled | repository_disabled }.policy do
        prevent :admin_feature_flags_issue_links
      end

      rule { can?(:guest_access) & iterations_available }.enable :read_iteration

      rule { can?(:reporter_access) }.policy do
        enable :admin_issue_board
      end

      rule { monitor_disabled }.policy do
        prevent :read_incident_management_oncall_schedule
        prevent :admin_incident_management_oncall_schedule
        prevent :read_incident_management_escalation_policy
        prevent :admin_incident_management_escalation_policy
      end

      rule { oncall_schedules_available & can?(:reporter_access) }.enable :read_incident_management_oncall_schedule
      rule { escalation_policies_available & can?(:reporter_access) }.enable :read_incident_management_escalation_policy

      rule { can?(:developer_access) }.policy do
        enable :admin_issue_board
        enable :read_vulnerability_feedback
        enable :create_vulnerability_feedback
        enable :destroy_vulnerability_feedback
        enable :update_vulnerability_feedback
        enable :admin_feature_flags_issue_links
        enable :read_project_audit_events
        enable :read_product_analytics
      end

      rule { can?(:reporter_access) & iterations_available }.policy do
        enable :create_iteration
        enable :admin_iteration
      end

      rule { can?(:read_project) & iterations_available }.enable :read_iteration

      rule { security_orchestration_policies_enabled & can?(:developer_access) }.policy do
        enable :read_security_orchestration_policies
      end

      rule { security_orchestration_policies_enabled & can?(:owner_access) }.policy do
        enable :modify_security_policy
        enable :update_security_orchestration_policy_project
      end

      rule { security_orchestration_policies_enabled & auditor }.policy do
        enable :read_security_orchestration_policies
      end

      rule { security_orchestration_policies_enabled & security_policy_project_available & can_commit_to_security_policy_project }.policy do
        enable :modify_security_policy
      end

      rule { security_dashboard_enabled & can?(:developer_access) }.policy do
        enable :read_security_resource
        enable :read_vulnerability_scanner
      end

      rule { coverage_fuzzing_enabled & can?(:developer_access) }.policy do
        enable :read_coverage_fuzzing
        enable :create_coverage_fuzzing_corpus
      end

      rule { on_demand_scans_enabled & can?(:developer_access) }.policy do
        enable :read_on_demand_dast_scan
        enable :create_on_demand_dast_scan
        enable :edit_on_demand_dast_scan
      end

      rule { can?(:read_merge_request) & can?(:read_pipeline) }.enable :read_merge_train

      rule { can?(:read_security_resource) }.policy do
        enable :read_project_security_dashboard
        enable :create_vulnerability
        enable :create_vulnerability_export
        enable :admin_vulnerability
        enable :admin_vulnerability_issue_link
        enable :admin_vulnerability_merge_request_link
        enable :admin_vulnerability_external_issue_link
      end

      rule { security_bot & auto_fix_enabled }.policy do
        enable :push_code
        enable :create_merge_request_from
        enable :create_vulnerability_feedback
        enable :admin_merge_request
      end

      rule { issues_disabled }.policy do
        prevent :read_issue_analytics
      end

      rule { merge_requests_disabled }.policy do
        prevent :read_project_merge_request_analytics
      end

      rule { issues_disabled & merge_requests_disabled }.policy do
        prevent(*create_read_update_admin_destroy(:iteration))
      end

      rule { dependency_scanning_enabled & can?(:download_code) }.enable :read_dependencies

      rule { license_scanning_enabled & can?(:download_code) }.enable :read_licenses

      rule { can?(:read_licenses) }.enable :read_software_license_policy

      rule { repository_mirrors_enabled & ((mirror_available & can?(:admin_project)) | admin) }.enable :admin_mirror

      rule { can?(:maintainer_access) }.policy do
        enable :push_code_to_protected_branches
        enable :admin_path_locks
        enable :read_approvers
        enable :update_approvers
        enable :modify_approvers_rules
        enable :modify_auto_fix_setting
        enable :modify_merge_request_author_setting
        enable :modify_merge_request_committer_setting
        enable :modify_product_analytics_settings
      end

      rule { license_scanning_enabled & can?(:maintainer_access) }.enable :admin_software_license_policy

      rule { oncall_schedules_available & can?(:maintainer_access) }.enable :admin_incident_management_oncall_schedule
      rule { escalation_policies_available & can?(:maintainer_access) }.enable :admin_incident_management_escalation_policy

      rule { auditor }.policy do
        enable :public_user_access
        prevent :request_access

        enable :read_build
        enable :read_environment
        enable :read_deployment
        enable :read_pages
        enable :read_project_audit_events
        enable :read_cluster
        enable :read_terraform_state
        enable :read_project_merge_request_analytics
        enable :read_approvers
        enable :read_on_demand_dast_scan

        enable :read_project_runners
      end

      rule { ~security_and_compliance_disabled & auditor }.policy do
        enable :access_security_and_compliance
      end

      rule { auditor & security_dashboard_enabled }.policy do
        enable :read_security_resource
        enable :read_vulnerability_scanner
      end

      rule { auditor & oncall_schedules_available }.policy do
        enable :read_incident_management_oncall_schedule
      end

      rule { auditor & escalation_policies_available }.policy do
        enable :read_incident_management_escalation_policy
      end

      rule { auditor & ~monitor_disabled }.policy do
        enable :read_alert_management_alert
      end

      rule { auditor & ~developer }.policy do
        prevent :create_vulnerability
        prevent :admin_vulnerability
        prevent :admin_vulnerability_issue_link
        prevent :admin_vulnerability_external_issue_link
        prevent :admin_vulnerability_merge_request_link
      end

      rule { auditor & ~guest }.policy do
        prevent :create_project
        prevent :create_issue
        prevent :create_note
        prevent :upload_file
      end

      rule { ~can?(:push_code) }.prevent :push_code_to_protected_branches

      rule { admin | maintainer }.enable :change_reject_unsigned_commits

      rule { reject_unsigned_commits_available }.enable :read_reject_unsigned_commits

      rule { ~reject_unsigned_commits_available }.prevent :change_reject_unsigned_commits

      rule { admin | maintainer }.enable :change_commit_committer_check

      rule { commit_committer_check_available }.enable :read_commit_committer_check

      rule { ~commit_committer_check_available }.prevent :change_commit_committer_check

      rule { admin | maintainer }.enable :change_commit_committer_name_check

      rule { commit_committer_name_check_available }.enable :read_commit_committer_name_check

      rule { ~commit_committer_name_check_available }.prevent :change_commit_committer_name_check

      rule { admin | maintainer }.enable :change_reject_non_dco_commits

      rule { reject_non_dco_commits_available }.enable :read_reject_non_dco_commits

      rule { ~reject_non_dco_commits_available }.prevent :change_reject_non_dco_commits

      rule { owner | reporter | internal_access | public_project }.enable :build_read_project

      rule { ~admin & owner & owner_cannot_destroy_project }.prevent :remove_project

      rule { ~admin & user_banned_from_namespace }.policy do
        prevent :read_project
      end

      with_scope :subject
      condition(:needs_new_sso_session) do
        ::Gitlab::Auth::GroupSaml::SsoEnforcer.group_access_restricted?(subject.group, user: @user, for_project: true)
      end

      with_scope :subject
      condition(:ip_enforcement_prevents_access) do
        !::Gitlab::IpRestriction::Enforcer.new(subject.group).allows_current_ip? if subject.group
      end

      with_scope :global
      condition(:owner_cannot_destroy_project) do
        ::Gitlab::CurrentSettings.current_application_settings
          .default_project_deletion_protection
      end

      # For public projects, SSO enforcement only applies to group members
      rule { public_project & needs_new_sso_session & group_member & ~admin & ~auditor }.policy do
        prevent :public_user_access
        prevent :public_access
      end

      rule { needs_new_sso_session & ~admin & ~auditor }.policy do
        prevent :guest_access
        prevent :reporter_access
        prevent :developer_access
        prevent :maintainer_access
        prevent :owner_access
      end

      with_scope :subject
      condition(:strict_ip_enforcement, scope: :subject) do
        ::Feature.enabled?(:strict_ip_enforcement, @subject)
      end

      rule { ip_enforcement_prevents_access & ~admin & ~auditor }.policy do
        prevent :read_project
        prevent :read_issue
        prevent :read_merge_request
        prevent :read_milestone
        prevent :read_container_image
        prevent :create_container_image
        prevent(*create_read_update_admin_destroy(:package))
      end

      rule { ip_enforcement_prevents_access & ~admin & ~auditor & strict_ip_enforcement }.policy do
        prevent_all
      end

      rule { locked_approvers_rules }.policy do
        prevent :modify_approvers_rules
      end

      rule { locked_merge_request_author_setting }.policy do
        prevent :modify_merge_request_author_setting
      end

      rule { locked_merge_request_committer_setting }.policy do
        prevent :modify_merge_request_committer_setting
      end

      rule { issue_analytics_enabled }.enable :read_issue_analytics

      rule { can?(:read_merge_request) & code_review_analytics_enabled }.enable :read_code_review_analytics

      rule { (admin | reporter) & dora4_analytics_available }
        .enable :read_dora4_analytics

      rule { (admin | reporter) & project_merge_request_analytics_available }
        .enable :read_project_merge_request_analytics

      rule { combined_project_analytics_dashboards_enabled }.enable :read_combined_project_analytics_dashboards

      rule { can?(:read_project) & requirements_available }.enable :read_requirement

      rule { requirements_available & (reporter | admin) }.policy do
        enable :create_requirement
        enable :create_requirement_test_report
        enable :admin_requirement
        enable :update_requirement
        enable :import_requirements
        enable :export_requirements
      end

      rule { requirements_available & (owner | admin) }.enable :destroy_requirement

      rule { quality_management_available & can?(:reporter_access) & can?(:create_issue) }.enable :create_test_case

      rule { compliance_framework_available & can?(:owner_access) }.enable :admin_compliance_framework

      rule { status_page_available & can?(:owner_access) }.enable :mark_issue_for_publication
      rule { status_page_available & can?(:developer_access) }.enable :publish_status_page

      rule { hidden }.policy do
        prevent :download_code
        prevent :build_download_code
      end

      rule { read_only }.policy do
        prevent(*readonly_abilities)

        readonly_features.each do |feature|
          prevent(*create_update_admin(feature))
        end
      end

      rule { auditor | can?(:developer_access) }.enable :add_project_to_instance_security_dashboard

      rule { (admin | maintainer) & group_merge_request_approval_settings_enabled }.policy do
        enable :admin_merge_request_approval_settings
      end

      rule { custom_roles_allowed & role_enables_read_code }.enable :read_code

      rule { can?(:create_issue) & okrs_enabled }.policy do
        enable :create_objective
        enable :create_key_result
      end

      rule { suggested_reviewers_bot & suggested_reviewers_available & resource_access_token_feature_available & resource_access_token_creation_allowed }.policy do
        enable :admin_project_member
        enable :create_resource_access_tokens
      end
    end

    override :lookup_access_level!
    def lookup_access_level!
      return ::Gitlab::Access::NO_ACCESS if needs_new_sso_session?
      return ::Gitlab::Access::NO_ACCESS if visual_review_bot?
      return ::Gitlab::Access::REPORTER if security_bot? && auto_fix_enabled?

      super
    end

    # Available in Core for self-managed but only paid, non-trial for .com to prevent abuse
    override :resource_access_token_create_feature_available?
    def resource_access_token_create_feature_available?
      return false unless resource_access_token_feature_available?
      return super unless ::Gitlab.com?

      namespace = project.namespace
      namespace.feature_available_non_trial?(:resource_access_token)
    end

    override :resource_access_token_feature_available?
    def resource_access_token_feature_available?
      return false if ::Gitlab::CurrentSettings.personal_access_tokens_disabled?

      super
    end

    override :namespace_catalog_available?
    def namespace_catalog_available?
      project.licensed_feature_available?(:ci_namespace_catalog) &&
        ::Feature.enabled?(:ci_private_catalog_beta, project)
    end
  end
end
