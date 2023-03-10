# frozen_string_literal: true

module Sidebars
  module YourWork
    module Menus
      class SecurityDashboardMenu < ::Sidebars::Menu
        override :title
        def title
          _('Security')
        end

        override :sprite_icon
        def sprite_icon
          'shield'
        end

        override :render?
        def render?
          context.show_security_dashboard
        end

        override :active_routes
        def active_routes
          { controller: 'security/application' }
        end

        override :configure_menu_items
        def configure_menu_items
          add_item(security_dashboard_item)
          add_item(vulnerability_report_item)
          add_item(security_settings_item)

          true
        end

        private

        def security_dashboard_item
          ::Sidebars::MenuItem.new(
            title: _('Security dashboard'),
            link: security_dashboard_path,
            active_routes: { path: 'security/dashboard#show' },
            item_id: :security_dashboard
          )
        end

        def vulnerability_report_item
          ::Sidebars::MenuItem.new(
            title: _('Vulnerability report'),
            link: security_vulnerabilities_path,
            active_routes: { path: 'security/vulnerabilities#index' },
            item_id: :vulnerability_report
          )
        end

        def security_settings_item
          ::Sidebars::MenuItem.new(
            title: _('Settings'),
            link: settings_security_dashboard_path,
            active_routes: { path: 'security/dashboard#settings' },
            item_id: :security_settings
          )
        end
      end
    end
  end
end
