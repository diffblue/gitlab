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

      condition(:runner_jobs_statistics_available) do
        ::License.feature_available?(:runner_jobs_statistics)
      end

      condition(:service_accounts_available) do
        ::License.feature_available?(:service_accounts)
      end

      condition(:instance_external_audit_events_enabled) do
        ::License.feature_available?(:external_audit_events) &&
          ::Feature.enabled?(:ff_external_audit_events)
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

      rule { admin & runner_jobs_statistics_available }.enable :read_jobs_statistics

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
    end
  end
end
