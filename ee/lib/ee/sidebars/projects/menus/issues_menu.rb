# frozen_string_literal: true

module EE
  module Sidebars
    module Projects
      module Menus
        module IssuesMenu
          extend ::Gitlab::Utils::Override

          override :configure_menu_items
          def configure_menu_items
            return false unless super

            add_item(iterations_menu_item)
            add_item(requirements_menu_item)

            true
          end

          private

          def iterations_menu_item
            if !context.project.licensed_feature_available?(:iterations) ||
              !can?(context.current_user, :read_iteration, context.project)
              return ::Sidebars::NilMenuItem.new(item_id: :iterations)
            end

            link = context.project.group&.iteration_cadences_feature_flag_enabled? ? project_iteration_cadences_path(context.project) : project_iterations_path(context.project)
            controller = context.project.group&.iteration_cadences_feature_flag_enabled? ? :iteration_cadences : :iterations

            ::Sidebars::MenuItem.new(
              title: _('Iterations'),
              link: link,
              active_routes: { controller: controller },
              item_id: :iterations
            )
          end

          def requirements_menu_item
            if !context.project.licensed_feature_available?(:requirements) ||
              !can?(context.current_user, :read_requirement, context.project)
              return ::Sidebars::NilMenuItem.new(item_id: :requirements)
            end

            ::Sidebars::MenuItem.new(
              title: _('Requirements'),
              link: project_requirements_management_requirements_path(context.project),
              active_routes: { path: 'requirements#index' },
              item_id: :requirements
            )
          end
        end
      end
    end
  end
end
