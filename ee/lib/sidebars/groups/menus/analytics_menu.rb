# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class AnalyticsMenu < ::Sidebars::Menu
        include Gitlab::Utils::StrongMemoize

        override :configure_menu_items
        def configure_menu_items
          add_item(cycle_analytics_menu_item)
          add_item(ci_cd_analytics_menu_item)
          add_item(contribution_analytics_menu_item)
          add_item(devops_adoption_menu_item)
          add_item(insights_analytics_menu_item)
          add_item(issues_analytics_menu_item)
          add_item(productivity_analytics_menu_item)
          add_item(repository_analytics_menu_item)

          true
        end

        override :link
        def link
          return cycle_analytics_menu_item.link if cycle_analytics_menu_item.render?

          super
        end

        override :extra_container_html_options
        def extra_container_html_options
          {
            class: 'shortcuts-analytics'
          }
        end

        override :title
        def title
          _('Analytics')
        end

        override :sprite_icon
        def sprite_icon
          'chart'
        end

        override :serialize_as_menu_item_args
        def serialize_as_menu_item_args
          nil
        end

        private

        def ci_cd_analytics_menu_item
          unless show_ci_cd_analytics?
            return ::Sidebars::NilMenuItem.new(item_id: :ci_cd_analytics)
          end

          ::Sidebars::MenuItem.new(
            title: context.is_super_sidebar ? _('CI/CD analytics') : _('CI/CD'),
            link: group_analytics_ci_cd_analytics_path(context.group),
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::AnalyzeMenu,
            active_routes: { path: 'groups/analytics/ci_cd_analytics#show' },
            item_id: :ci_cd_analytics
          )
        end

        def show_ci_cd_analytics?
          context.group.licensed_feature_available?(:group_ci_cd_analytics) &&
          can?(context.current_user, :view_group_ci_cd_analytics, context.group)
        end

        def contribution_analytics_menu_item
          unless show_contribution_analytics?
            return ::Sidebars::NilMenuItem.new(item_id: :contribution_analytics)
          end

          ::Sidebars::MenuItem.new(
            title: context.is_super_sidebar ? _('Contribution analytics') : _('Contribution'),
            link: group_contribution_analytics_path(context.group),
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::AnalyzeMenu,
            active_routes: { path: 'groups/contribution_analytics#show' },
            container_html_options: { data: { placement: 'right' } },
            item_id: :contribution_analytics
          )
        end

        def show_contribution_analytics?
          can?(context.current_user, :read_group_contribution_analytics, context.group)
        end

        def devops_adoption_menu_item
          unless can?(context.current_user, :view_group_devops_adoption, context.group)
            return ::Sidebars::NilMenuItem.new(item_id: :devops_adoption)
          end

          ::Sidebars::MenuItem.new(
            title: _('DevOps adoption'),
            link: group_analytics_devops_adoption_path(context.group),
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::AnalyzeMenu,
            active_routes: { path: 'groups/analytics/devops_adoption#show' },
            item_id: :devops_adoption
          )
        end

        def insights_analytics_menu_item
          unless context.group.insights_available?
            return ::Sidebars::NilMenuItem.new(item_id: :insights)
          end

          ::Sidebars::MenuItem.new(
            title: _('Insights'),
            link: group_insights_path(context.group),
            active_routes: { path: 'groups/insights#show' },
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::AnalyzeMenu,
            container_html_options: { class: 'shortcuts-group-insights' },
            item_id: :insights
          )
        end

        def issues_analytics_menu_item
          unless context.group.licensed_feature_available?(:issues_analytics)
            return ::Sidebars::NilMenuItem.new(item_id: :issues_analytics)
          end

          ::Sidebars::MenuItem.new(
            title: context.is_super_sidebar ? _('Issue analytics') : _('Issue'),
            link: group_issues_analytics_path(context.group),
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::AnalyzeMenu,
            active_routes: { path: 'issues_analytics#show' },
            item_id: :issues_analytics
          )
        end

        def productivity_analytics_menu_item
          unless show_productivity_analytics?
            return ::Sidebars::NilMenuItem.new(item_id: :productivity_analytics)
          end

          ::Sidebars::MenuItem.new(
            title: context.is_super_sidebar ? _('Productivity analytics') : _('Productivity'),
            link: group_analytics_productivity_analytics_path(context.group),
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::AnalyzeMenu,
            active_routes: { path: 'groups/analytics/productivity_analytics#show' },
            item_id: :productivity_analytics
          )
        end

        def show_productivity_analytics?
          context.group.licensed_feature_available?(:productivity_analytics) &&
            can?(context.current_user, :view_productivity_analytics, context.group)
        end

        def repository_analytics_menu_item
          unless show_repository_analytics?
            return ::Sidebars::NilMenuItem.new(item_id: :repository_analytics)
          end

          ::Sidebars::MenuItem.new(
            title: context.is_super_sidebar ? _('Repository analytics') : _('Repository'),
            link: group_analytics_repository_analytics_path(context.group),
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::AnalyzeMenu,
            active_routes: { path: 'groups/analytics/repository_analytics#show' },
            item_id: :repository_analytics
          )
        end

        def show_repository_analytics?
          context.group.licensed_feature_available?(:group_coverage_reports) &&
            can?(context.current_user, :read_group_repository_analytics, context.group)
        end

        def cycle_analytics_menu_item
          strong_memoize(:cycle_analytics_menu_item) do
            unless can?(context.current_user, :read_group_cycle_analytics, context.group)
              next ::Sidebars::NilMenuItem.new(item_id: :cycle_analytics)
            end

            ::Sidebars::MenuItem.new(
              title: context.is_super_sidebar ? _('Value stream analytics') : _('Value stream'),
              link: group_analytics_cycle_analytics_path(context.group),
              super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::AnalyzeMenu,
              active_routes: { path: 'groups/analytics/cycle_analytics#show' },
              item_id: :cycle_analytics
            )
          end
        end
      end
    end
  end
end

Sidebars::Groups::Menus::AnalyticsMenu.prepend_mod
