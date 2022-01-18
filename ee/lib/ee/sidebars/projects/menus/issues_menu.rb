# frozen_string_literal: true

module EE
  module Sidebars
    module Projects
      module Menus
        module IssuesMenu
          extend ::Gitlab::Utils::Override

          override :configure_menu_items
          def configure_menu_items
            return false if !super && !show_jira_menu_items?

            add_item(iterations_menu_item)
            add_item(requirements_menu_item)
            add_item(jira_issue_list_menu_item)
            add_item(jira_external_link_menu_item)

            true
          end

          def show_jira_menu_items?
            external_issue_tracker.is_a?(Integrations::Jira) && context.jira_issues_integration
          end

          private

          def iterations_menu_item
            if !show_issues_menu_items? ||
              !context.project.licensed_feature_available?(:iterations) ||
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
            if !show_issues_menu_items? ||
              !context.project.licensed_feature_available?(:requirements) ||
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

          def external_issue_tracker
            @external_issue_tracker ||= context.project.external_issue_tracker
          end

          def jira_issue_list_menu_item
            return ::Sidebars::NilMenuItem.new(item_id: :jira_issue_list) unless show_jira_menu_items?

            ::Sidebars::MenuItem.new(
              title: s_('JiraService|Jira issues'),
              link: project_integrations_jira_issues_path(context.project),
              active_routes: { controller: 'projects/integrations/jira/issues' },
              item_id: :jira_issue_list
            )
          end

          def jira_external_link_menu_item
            return ::Sidebars::NilMenuItem.new(item_id: :jira_external_link) unless show_jira_menu_items?

            ::Sidebars::MenuItem.new(
              title: s_('JiraService|Open Jira'),
              link: external_issue_tracker.issue_tracker_path,
              active_routes: {},
              item_id: :jira_external_link,
              sprite_icon: 'external-link',
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
