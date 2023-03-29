# frozen_string_literal: true

module EE
  module Sidebars
    module Projects
      module Menus
        module MonitorMenu
          extend ::Gitlab::Utils::Override

          override :configure_menu_items
          def configure_menu_items
            return false unless super

            insert_item_after(:incidents, on_call_schedules_menu_item)
            insert_item_after(:on_call_schedules, escalation_policies_menu_item)

            true
          end

          private

          def on_call_schedules_menu_item
            unless can?(context.current_user, :read_incident_management_oncall_schedule, context.project)
              return ::Sidebars::NilMenuItem.new(item_id: :on_call_schedules)
            end

            ::Sidebars::MenuItem.new(
              title: _('On-call Schedules'),
              link: project_incident_management_oncall_schedules_path(context.project),
              super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::MonitorMenu,
              active_routes: { controller: :oncall_schedules },
              item_id: :on_call_schedules
            )
          end

          def escalation_policies_menu_item
            unless can?(context.current_user, :read_incident_management_escalation_policy, context.project)
              return ::Sidebars::NilMenuItem.new(item_id: :escalation_policies)
            end

            ::Sidebars::MenuItem.new(
              title: _('Escalation Policies'),
              link: project_incident_management_escalation_policies_path(context.project),
              super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::MonitorMenu,
              active_routes: { controller: :escalation_policies },
              item_id: :escalation_policies
            )
          end
        end
      end
    end
  end
end
