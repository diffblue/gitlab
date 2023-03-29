# frozen_string_literal: true

module EE
  module Sidebars
    module Projects
      module Menus
        module SecurityComplianceMenu
          extend ::Gitlab::Utils::Override

          override :configure_menu_items
          def configure_menu_items
            return false unless can?(context.current_user, :access_security_and_compliance, context.project)

            add_item(discover_project_security_menu_item)
            add_item(security_dashboard_menu_item)
            add_item(vulnerability_report_menu_item)
            add_item(on_demand_scans_menu_item)
            add_item(dependencies_menu_item)
            add_item(license_compliance_menu_item)
            add_item(scan_policies_menu_item)
            add_item(audit_events_menu_item)
            add_item(configuration_menu_item)

            true
          end

          private

          override :configuration_menu_item_paths
          def configuration_menu_item_paths
            super + %w[
              projects/security/sast_configuration#show
              projects/security/api_fuzzing_configuration#show
              projects/security/dast_configuration#show
              projects/security/dast_profiles#show
              projects/security/dast_site_profiles#new
              projects/security/dast_site_profiles#edit
              projects/security/dast_scanner_profiles#new
              projects/security/dast_scanner_profiles#edit
              projects/security/corpus_management#show
            ]
          end

          override :render_configuration_menu_item?
          def render_configuration_menu_item?
            super ||
              (context.project.licensed_feature_available?(:security_dashboard) && can?(context.current_user, :read_project_security_dashboard, context.project))
          end

          def discover_project_security_menu_item
            unless context.show_discover_project_security
              return ::Sidebars::NilMenuItem.new(item_id: :discover_project_security)
            end

            ::Sidebars::MenuItem.new(
              title: _('Security capabilities'),
              link: project_security_discover_path(context.project),
              super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::SecureMenu,
              active_routes: { path: 'projects/security/discover#show' },
              item_id: :discover_project_security
            )
          end

          def security_dashboard_menu_item
            unless can?(context.current_user, :read_project_security_dashboard, context.project)
              return ::Sidebars::NilMenuItem.new(item_id: :dashboard)
            end

            ::Sidebars::MenuItem.new(
              title: _('Security dashboard'),
              link: project_security_dashboard_index_path(context.project),
              super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::SecureMenu,
              active_routes: { path: 'projects/security/dashboard#index' },
              item_id: :dashboard
            )
          end

          def vulnerability_report_menu_item
            unless can?(context.current_user, :read_project_security_dashboard, context.project)
              return ::Sidebars::NilMenuItem.new(item_id: :vulnerability_report)
            end

            ::Sidebars::MenuItem.new(
              title: _('Vulnerability report'),
              link: project_security_vulnerability_report_index_path(context.project),
              super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::SecureMenu,
              active_routes: { path: %w[projects/security/vulnerability_report#index projects/security/vulnerabilities#show] },
              item_id: :vulnerability_report
            )
          end

          def on_demand_scans_menu_item
            unless can?(context.current_user, :read_on_demand_dast_scan, context.project)
              return ::Sidebars::NilMenuItem.new(item_id: :on_demand_scans)
            end

            link = project_on_demand_scans_path(context.project)

            ::Sidebars::MenuItem.new(
              title: s_('OnDemandScans|On-demand scans'),
              link: link,
              super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::SecureMenu,
              item_id: :on_demand_scans,
              active_routes: { path: %w[
                projects/on_demand_scans#index
                projects/on_demand_scans#new
                projects/on_demand_scans#edit
              ] }
            )
          end

          def dependencies_menu_item
            unless can?(context.current_user, :read_dependencies, context.project)
              return ::Sidebars::NilMenuItem.new(item_id: :dependency_list)
            end

            ::Sidebars::MenuItem.new(
              title: _('Dependency list'),
              link: project_dependencies_path(context.project),
              super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::SecureMenu,
              active_routes: { path: 'projects/dependencies#index' },
              item_id: :dependency_list
            )
          end

          def license_compliance_menu_item
            unless can?(context.current_user, :read_licenses, context.project)
              return ::Sidebars::NilMenuItem.new(item_id: :license_compliance)
            end

            ::Sidebars::MenuItem.new(
              title: _('License compliance'),
              link: project_licenses_path(context.project),
              super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::SecureMenu,
              active_routes: { path: 'projects/licenses#index' },
              item_id: :license_compliance
            )
          end

          def scan_policies_menu_item
            unless can?(context.current_user, :read_security_orchestration_policies, context.project)
              return ::Sidebars::NilMenuItem.new(item_id: :scan_policies)
            end

            ::Sidebars::MenuItem.new(
              title: _('Policies'),
              link: project_security_policies_path(context.project),
              super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::SecureMenu,
              active_routes: { controller: ['projects/security/policies'] },
              item_id: :scan_policies
            )
          end

          def audit_events_menu_item
            unless show_audit_events?
              return ::Sidebars::NilMenuItem.new(item_id: :audit_events)
            end

            ::Sidebars::MenuItem.new(
              title: _('Audit events'),
              link: project_audit_events_path(context.project),
              super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::SecureMenu,
              active_routes: { controller: :audit_events },
              item_id: :audit_events
            )
          end

          def show_audit_events?
            can?(context.current_user, :read_project_audit_events, context.project) &&
              (context.project.licensed_feature_available?(:audit_events) || context.show_promotions)
          end
        end
      end
    end
  end
end
