# frozen_string_literal: true

module EE
  module Sidebars
    module Projects
      module Menus
        module CiCdMenu
          extend ::Gitlab::Utils::Override

          override :configure_menu_items
          def configure_menu_items
            return false unless super

            add_item(test_cases_menu_item)

            true
          end

          private

          override :pipelines_routes
          def pipelines_routes
            super + %w[
              pipelines#security
              pipelines#licenses
              pipelines#codequality_report
            ]
          end

          def test_cases_menu_item
            if !context.project.licensed_feature_available?(:quality_management) ||
              !can?(context.current_user, :read_issue, context.project)
              return ::Sidebars::NilMenuItem.new(item_id: :test_cases)
            end

            ::Sidebars::MenuItem.new(
              title: _('Test cases'),
              link: project_quality_test_cases_path(context.project),
              super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::BuildMenu,
              container_html_options: { class: 'shortcuts-test-cases' },
              active_routes: { controller: :test_cases },
              item_id: :test_cases
            )
          end
        end
      end
    end
  end
end
