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
              active_routes: { path: iterations_paths },
              item_id: :iterations
            )
          end

          def iterations_enabled?
            ::Feature.enabled?(:group_iterations, context.group, default_enabled: true) && context.group.licensed_feature_available?(:iterations)
          end

          def user_can_access_iterations?
            (context.group.iteration_cadences_feature_flag_enabled? && can?(context.current_user, :read_iteration_cadence, context.group)) ||
              can?(context.current_user, :read_iteration, context.group)
          end

          def iterations_link
            strong_memoize(:iterations_link) do
              context.group.iteration_cadences_feature_flag_enabled? ? group_iteration_cadences_path(context.group) : group_iterations_path(context.group)
            end
          end

          def iterations_paths
            strong_memoize(:iterations_paths) do
              %w[iterations#index iterations#show iterations#new].tap do |paths|
                paths << 'iteration_cadences#index' if context.group.iteration_cadences_feature_flag_enabled?
              end
            end
          end
        end
      end
    end
  end
end
