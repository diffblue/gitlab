# frozen_string_literal: true

module EE
  module GlobalPolicy
    extend ActiveSupport::Concern

    prepended do
      condition(:operations_dashboard_available) do
        License.feature_available?(:operations_dashboard)
      end

      condition(:pages_size_limit_available) do
        License.feature_available?(:pages_size_limit)
      end

      condition(:adjourned_project_deletion_available) do
        License.feature_available?(:adjourned_deletion_for_projects_and_groups)
      end

      condition(:project_owners_list_project_pending_deletion) do
        (::Feature.enabled?(:project_owners_list_project_pending_deletion, default_enabled: :yaml) || can?(:admin_all_resources))
      end

      condition(:export_user_permissions_available) do
        ::License.feature_available?(:export_user_permissions)
      end

      condition(:top_level_group_creation_enabled) do
        if ::Gitlab.com?
          ::Feature.enabled?(:top_level_group_creation_enabled, type: :ops, default_enabled: true)
        else
          true
        end
      end

      condition(:instance_devops_adoption_available) do
        ::License.feature_available?(:instance_level_devops_adoption)
      end

      rule { ~anonymous & operations_dashboard_available }.enable :read_operations_dashboard

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

      rule { ~anonymous }.policy do
        enable :view_productivity_analytics
      end

      rule { ~(admin | allow_to_manage_default_branch_protection) }.policy do
        prevent :create_group_with_default_branch_protection
      end

      rule { adjourned_project_deletion_available & project_owners_list_project_pending_deletion }.policy do
        enable :list_removable_projects
      end

      rule { adjourned_project_deletion_available }.policy do
        enable :delay_project_deletions
      end

      rule { export_user_permissions_available & admin }.enable :export_user_permissions

      rule { can?(:create_group) }.enable :create_group_via_api
      rule { ~top_level_group_creation_enabled }.prevent :create_group_via_api
    end
  end
end
