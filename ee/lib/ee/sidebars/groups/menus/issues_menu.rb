# frozen_string_literal: true

module EE
  module Sidebars
    module Groups
      module Menus
        module IssuesMenu
          extend ::Gitlab::Utils::Override

          override :configure_menu_items
          def configure_menu_items
            return false unless super

            add_item(iterations_menu_item)

            true
          end

          private

          def iterations_menu_item
            if !iterations_enabled? || !user_can_access_iterations?
              return ::Sidebars::NilMenuItem.new(item_id: :iterations)
            end

            ::Sidebars::MenuItem.new(
              title: _('Iterations'),
              link: iterations_link,
              super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::PlanMenu,
              active_routes: { path: iterations_paths },
              item_id: :iterations
            )
          end

          def iterations_enabled?
            context.group.licensed_feature_available?(:iterations)
          end

          def user_can_access_iterations?
            can?(context.current_user, :read_iteration_cadence, context.group) ||
              can?(context.current_user, :read_iteration, context.group)
          end

          def iterations_link
            group_iteration_cadences_path(context.group)
          end

          def iterations_paths
            strong_memoize(:iterations_paths) do
              %w[iterations#index iterations#show iterations#new].tap do |paths|
                paths << 'iteration_cadences#index'
              end
            end
          end
        end
      end
    end
  end
end
