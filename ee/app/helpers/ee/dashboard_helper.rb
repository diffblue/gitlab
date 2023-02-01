# frozen_string_literal: true

module EE
  module DashboardHelper
    extend ::Gitlab::Utils::Override

    def controller_action_to_child_dashboards(controller = controller_name, action = action_name)
      case "#{controller}##{action}"
      when 'projects#index', 'root#index', 'projects#starred', 'projects#trending'
        %w(projects)
      when 'dashboard#activity'
        %w(starred_project_activity project_activity)
      when 'groups#index'
        %w(groups)
      when 'todos#index'
        %w(todos)
      when 'dashboard#issues'
        %w(issues)
      when 'dashboard#merge_requests'
        %w(merge_requests)
      else
        []
      end
    end

    def user_default_dashboard?(user)
      controller_action_to_child_dashboards.any?(user.dashboard)
    end

    def has_start_trial?
      !current_user.has_current_license? && current_user.can_admin_all_resources?
    end

    private

    override :get_dashboard_nav_links
    def get_dashboard_nav_links
      super.tap do |links|
        if can?(current_user, :read_operations_dashboard)
          links << :environments
          links << :operations
        end

        if security_dashboard_available?
          links << :security
        end
      end
    end

    def security_dashboard_available?
      security_dashboard = InstanceSecurityDashboard.new(current_user)

      security_dashboard.feature_available?(:security_dashboard) &&
        can?(current_user, :read_instance_security_dashboard, security_dashboard)
    end
  end
end
