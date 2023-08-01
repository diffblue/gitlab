# frozen_string_literal: true

module EE
  module Sidebars
    module Projects
      module Menus
        module SettingsMenu
          extend ::Gitlab::Utils::Override

          override :configure_menu_items
          def configure_menu_items
            return false unless super

            insert_item_after(:monitor, analytics_menu_item)

            true
          end

          def analytics_menu_item
            unless ::Feature.enabled?(:combined_analytics_dashboards, context.project)
              return ::Sidebars::NilMenuItem.new(item_id: :analytics)
            end

            ::Sidebars::MenuItem.new(
              title: _('Analytics'),
              link: project_settings_analytics_path(context.project),
              active_routes: { path: %w[analytics#index] },
              item_id: :analytics
            )
          end
        end
      end
    end
  end
end
