# frozen_string_literal: true

module EE
  module Sidebars
    module Projects
      module Menus
        module IssuesMenu
          extend ::Gitlab::Utils::Override

          override :configure_menu_items
          def configure_menu_items
            return false unless super || show_jira_menu_items? \
              || show_zentao_menu_items?

            add_item(iterations_menu_item)
            add_item(requirements_menu_item)
            add_item(jira_issue_list_menu_item)
            add_item(jira_external_link_menu_item)
            add_item(zentao_issue_list_menu_item)
            add_item(zentao_external_link_menu_item)

            true
          end

          def show_jira_menu_items?
            external_issue_tracker.is_a?(Integrations::Jira) && context.jira_issues_integration
          end

          def show_zentao_menu_items?
            zentao_active? && \
              ::Integrations::Zentao.issues_license_available?(context.project)
          end

          private

          def iterations_menu_item
            if !show_issues_menu_items? ||
              context.project.personal? ||
              !context.project.licensed_feature_available?(:iterations) ||
              !can?(context.current_user, :read_iteration, context.project)
              return ::Sidebars::NilMenuItem.new(item_id: :iterations)
            end

            ::Sidebars::MenuItem.new(
              title: _('Iterations'),
              link: project_iteration_cadences_path(context.project),
              super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::PlanMenu,
              active_routes: { controller: :iteration_cadences },
              item_id: :iterations
            )
          end

          def requirements_menu_item
            if !show_issues_menu_items? ||
              !context.project.licensed_feature_available?(:requirements) ||
              !can?(context.current_user, :read_requirement, context.project)
              return ::Sidebars::NilMenuItem.new(item_id: :requirements)
            end

            ::Sidebars::MenuItem.new(
              title: _('Requirements'),
              link: project_requirements_management_requirements_path(context.project),
              super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::PlanMenu,
              active_routes: { path: 'requirements#index' },
              item_id: :requirements
            )
          end

          def external_issue_tracker
            @external_issue_tracker ||= context.project.external_issue_tracker
          end

          def jira_issue_list_menu_item
            return ::Sidebars::NilMenuItem.new(item_id: :jira_issue_list) unless show_jira_menu_items?

            ::Sidebars::MenuItem.new(
              title: s_('JiraService|Jira issues'),
              link: project_integrations_jira_issues_path(context.project),
              super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::PlanMenu,
              active_routes: { controller: 'projects/integrations/jira/issues' },
              item_id: :jira_issue_list
            )
          end

          def jira_external_link_menu_item
            return ::Sidebars::NilMenuItem.new(item_id: :jira_external_link) unless show_jira_menu_items?

            ::Sidebars::MenuItem.new(
              title: s_('JiraService|Open Jira'),
              link: external_issue_tracker.issue_tracker_path,
              super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::PlanMenu,
              active_routes: {},
              item_id: :jira_external_link,
              sprite_icon: context.is_super_sidebar ? nil : 'external-link',
              container_html_options: {
                target: '_blank',
                rel: 'noopener noreferrer'
              }
            )
          end

          def zentao_active?
            !!zentao_integration&.active?
          end

          def zentao_issue_list_menu_item
            return ::Sidebars::NilMenuItem.new(item_id: :zentao_issue_list) unless show_zentao_menu_items?

            ::Sidebars::MenuItem.new(
              title: s_('ZentaoIntegration|ZenTao issues'),
              link: project_integrations_zentao_issues_path(context.project),
              super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::PlanMenu,
              active_routes: { controller: 'projects/integrations/zentao/issues' },
              item_id: :zentao_issue_list
            )
          end

          def zentao_integration
            @zentao_integration ||= context.project.zentao_integration
          end

          def zentao_external_link_menu_item
            return ::Sidebars::NilMenuItem.new(item_id: :zentao_external_link) unless show_zentao_menu_items?

            ::Sidebars::MenuItem.new(
              title: s_('ZentaoIntegration|Open ZenTao'),
              link: zentao_integration.url,
              super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::PlanMenu,
              active_routes: {},
              item_id: :zentao_external_link,
              sprite_icon: context.is_super_sidebar ? nil : 'external-link',
              container_html_options: {
                target: '_blank',
                rel: 'noopener noreferrer'
              }
            )
          end
        end
      end
    end
  end
end
