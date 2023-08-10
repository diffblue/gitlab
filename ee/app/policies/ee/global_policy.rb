# frozen_string_literal: true

module EE
  module GlobalPolicy
    extend ActiveSupport::Concern

    prepended do
      condition(:operations_dashboard_available) do
        License.feature_available?(:operations_dashboard)
      end

      condition(:remote_development_available) do
        ::Feature.enabled?(:remote_development_feature_flag) && License.feature_available?(:remote_development)
      end

      condition(:pages_size_limit_available) do
        License.feature_available?(:pages_size_limit)
      end

      condition(:adjourned_project_deletion_available) do
        License.feature_available?(:adjourned_deletion_for_projects_and_groups)
      end

      condition(:export_user_permissions_available) do
        ::License.feature_available?(:export_user_permissions)
      end

      condition(:top_level_group_creation_enabled) do
        if ::Gitlab.com?
          ::Feature.enabled?(:top_level_group_creation_enabled, type: :ops)
        else
          true
        end
      end

      condition(:instance_devops_adoption_available) do
        ::License.feature_available?(:instance_level_devops_adoption)
      end

      condition(:runner_performance_insights_available) do
        ::License.feature_available?(:runner_performance_insights)
      end

      condition(:runner_upgrade_management_available) do
        License.feature_available?(:runner_upgrade_management)
      end

      condition(:service_accounts_available) do
        ::License.feature_available?(:service_accounts)
      end

      condition(:instance_external_audit_events_enabled) do
        ::License.feature_available?(:external_audit_events) &&
          ::Feature.enabled?(:ff_external_audit_events)
      end

      condition(:code_suggestions_licensed) do
        next true if ::Gitlab.org_or_com?

        ::License.feature_available?(:code_suggestions)
      end

      condition(:code_suggestions_enabled_by_instance) do
        next true if ::Gitlab.org_or_com?

        ::Gitlab::CurrentSettings.instance_level_code_suggestions_enabled
      end

      condition(:code_suggestions_enabled_by_user) do
        next true unless ::Gitlab.org_or_com?

        @user&.code_suggestions_enabled?
      end

      condition(:code_suggestions_disabled_by_group) do
        next false unless ::Gitlab.org_or_com?
        next false unless @user

        @user.code_suggestions_disabled_by_group?
      end

      condition(:user_has_paid_namespace) do
        next false unless @user

        @user.has_paid_namespace?
      end

      rule { ~anonymous & operations_dashboard_available }.enable :read_operations_dashboard

      rule { ~anonymous & remote_development_available }.enable :read_workspace

      rule { admin & instance_devops_adoption_available }.policy do
        enable :manage_devops_adoption_namespaces
        enable :view_instance_devops_adoption
      end

      rule { admin }.policy do
        enable :read_licenses
        enable :destroy_licenses
        enable :read_all_geo
        enable :manage_subscription
      end

      rule { admin & pages_size_limit_available }.enable :update_max_pages_size

      rule { admin & runner_performance_insights_available }.enable :read_jobs_statistics

      rule { admin & service_accounts_available }.enable :admin_service_accounts

      rule { ~anonymous }.policy do
        enable :view_productivity_analytics
      end

      rule { ~(admin | allow_to_manage_default_branch_protection) }.policy do
        prevent :create_group_with_default_branch_protection
      end

      rule { adjourned_project_deletion_available }.policy do
        enable :list_removable_projects
      end

      rule { export_user_permissions_available & admin }.enable :export_user_permissions

      rule { can?(:create_group) }.enable :create_group_via_api
      rule { ~top_level_group_creation_enabled }.prevent :create_group_via_api

      rule { admin & instance_external_audit_events_enabled }.policy do
        enable :admin_instance_external_audit_events
      end

      rule { code_suggestions_licensed & code_suggestions_enabled_by_user & code_suggestions_enabled_by_instance }
        .enable :access_code_suggestions
      rule { code_suggestions_disabled_by_group }.prevent :access_code_suggestions

      rule { runner_upgrade_management_available | user_has_paid_namespace }.enable :read_runner_upgrade_status
    end
  end
end
