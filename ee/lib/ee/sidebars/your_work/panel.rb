# frozen_string_literal: true

module EE
  module Sidebars
    module YourWork
      module Panel
        extend ::Gitlab::Utils::Override

        override :configure_menus
        def configure_menus
          super

          add_menu(workspaces_menu)
          add_menu(environments_dashboard_menu)
          add_menu(operations_dashboard_menu)
          add_menu(security_dashboard_menu)

          true
        end

        private

        def workspaces_menu
          ::Sidebars::YourWork::Menus::WorkspacesMenu.new(context)
        end

        def environments_dashboard_menu
          ::Sidebars::YourWork::Menus::EnvironmentsDashboardMenu.new(context)
        end

        def operations_dashboard_menu
          ::Sidebars::YourWork::Menus::OperationsDashboardMenu.new(context)
        end

        def security_dashboard_menu
          ::Sidebars::YourWork::Menus::SecurityDashboardMenu.new(context)
        end
      end
    end
  end
end
