# frozen_string_literal: true

module EE
  module Sidebars
    module Admin
      module Menus
        module MonitoringMenu
          extend ::Gitlab::Utils::Override

          override :configure_menu_items
          def configure_menu_items
            return false unless super

            insert_item_after(:health_check, audit_events_menu_item)

            true
          end

          private

          def audit_events_menu_item
            unless ::License.feature_available?(:admin_audit_log)
              return ::Sidebars::NilMenuItem.new(item_id: :audit_logs)
            end

            ::Sidebars::MenuItem.new(
              title: _('Audit Events'),
              link: admin_audit_logs_path,
              active_routes: { path: 'admin/audit_logs#index' },
              item_id: :audit_logs,
              container_html_options: { 'data-qa-selector': 'admin_monitoring_audit_logs_link' }
            )
          end
        end
      end
    end
  end
end
