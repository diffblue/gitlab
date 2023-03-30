# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class SecurityComplianceMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          add_item(security_dashboard_menu_item)
          add_item(vulnerability_report_menu_item)
          add_item(compliance_menu_item)
          add_item(credentials_menu_item)
          add_item(scan_policies_menu_item)
          add_item(audit_events_menu_item)

          true
        end

        override :link
        def link
          return group_security_discover_path(context.group) if renderable_items.empty?

          super
        end

        override :title
        def title
          renderable_items.any? ? _('Security and Compliance') : _('Security')
        end

        override :sprite_icon
        def sprite_icon
          'shield'
        end

        override :render?
        def render?
          super || context.show_discover_group_security
        end

        override :active_routes
        def active_routes
          return {} if renderable_items.empty?

          { page: link }
        end

        override :serialize_as_menu_item_args
        def serialize_as_menu_item_args
          nil
        end

        private

        def security_dashboard_menu_item
          unless context.group.licensed_feature_available?(:security_dashboard)
            return ::Sidebars::NilMenuItem.new(item_id: :security_dashboard)
          end

          ::Sidebars::MenuItem.new(
            title: _('Security dashboard'),
            link: group_security_dashboard_path(context.group),
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::SecureMenu,
            active_routes: { path: 'dashboard#show' },
            item_id: :security_dashboard
          )
        end

        def vulnerability_report_menu_item
          unless context.group.licensed_feature_available?(:security_dashboard)
            return ::Sidebars::NilMenuItem.new(item_id: :vulnerability_report)
          end

          ::Sidebars::MenuItem.new(
            title: _('Vulnerability report'),
            link: group_security_vulnerabilities_path(context.group),
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::SecureMenu,
            active_routes: { path: 'vulnerabilities#index' },
            item_id: :vulnerability_report
          )
        end

        def compliance_menu_item
          unless group_level_compliance_dashboard_available?
            return ::Sidebars::NilMenuItem.new(item_id: :compliance)
          end

          ::Sidebars::MenuItem.new(
            title: _('Compliance report'),
            link: group_security_compliance_dashboard_path(context.group),
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::SecureMenu,
            active_routes: { path: 'compliance_dashboards#show' },
            item_id: :compliance
          )
        end

        def group_level_compliance_dashboard_available?
          context.group.licensed_feature_available?(:group_level_compliance_dashboard) &&
            can?(context.current_user, :read_group_compliance_dashboard, context.group)
        end

        def credentials_menu_item
          unless group_level_credentials_inventory_available?
            return ::Sidebars::NilMenuItem.new(item_id: :credentials)
          end

          ::Sidebars::MenuItem.new(
            title: _('Credentials'),
            link: group_security_credentials_path(context.group),
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::SecureMenu,
            active_routes: { path: 'credentials#index' },
            item_id: :credentials
          )
        end

        def group_level_credentials_inventory_available?
          context.group.licensed_feature_available?(:credentials_inventory) &&
            can?(context.current_user, :read_group_credentials_inventory, context.group) &&
            context.group.enforced_group_managed_accounts?
        end

        def scan_policies_menu_item
          unless group_level_security_policies_available?
            return ::Sidebars::NilMenuItem.new(item_id: :scan_policies)
          end

          ::Sidebars::MenuItem.new(
            title: _('Policies'),
            link: group_security_policies_path(context.group),
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::SecureMenu,
            active_routes: { controller: ['groups/security/policies'] },
            item_id: :scan_policies
          )
        end

        def group_level_security_policies_available?
          can?(context.current_user, :read_security_orchestration_policies, context.group)
        end

        def audit_events_menu_item
          unless group_level_audit_events_available?
            return ::Sidebars::NilMenuItem.new(item_id: :audit_events)
          end

          ::Sidebars::MenuItem.new(
            title: _('Audit events'),
            link: group_audit_events_path(context.group),
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::SecureMenu,
            active_routes: { path: 'audit_events#index' },
            item_id: :audit_events
          )
        end

        def group_level_audit_events_available?
          context.group.licensed_feature_available?(:audit_events) &&
            can?(context.current_user, :read_group_audit_events, context.group)
        end
      end
    end
  end
end
