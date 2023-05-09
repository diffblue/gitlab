# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class EpicsMenu < ::Sidebars::Menu
        include Gitlab::Utils::StrongMemoize

        override :configure_menu_items
        def configure_menu_items
          return false unless can?(context.current_user, :read_epic, context.group)

          add_item(epic_list_menu_item)
          add_item(boards_menu_item)
          add_item(roadmap_menu_item)

          true
        end

        override :title
        def title
          _('Epics')
        end

        override :sprite_icon
        def sprite_icon
          'epic'
        end

        override :active_routes
        def active_routes
          { controller: :epics }
        end

        override :has_pill?
        def has_pill?
          true
        end

        override :pill_count
        def pill_count
          strong_memoize(:pill_count) do
            count_service = ::Groups::EpicsCountService
            count = count_service.new(context.group, context.current_user).count

            format_cached_count(count_service::CACHED_COUNT_THRESHOLD, count)
          end
        end

        override :serialize_as_menu_item_args
        def serialize_as_menu_item_args
          super.merge({
            pill_count: pill_count,
            has_pill: has_pill?,
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::PlanMenu,
            item_id: :group_epic_list
          })
        end

        private

        def epic_list_menu_item
          ::Sidebars::MenuItem.new(
            title: _('List'),
            link: group_epics_path(context.group),
            super_sidebar_parent: ::Sidebars::NilMenuItem,
            active_routes: { path: 'epics#index' },
            container_html_options: { class: 'home' },
            item_id: :epic_list
          )
        end

        def boards_menu_item
          ::Sidebars::MenuItem.new(
            title: context.is_super_sidebar ? _('Epic boards') : _('Boards'),
            link: group_epic_boards_path(context.group),
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::PlanMenu,
            active_routes: { path: %w[epic_boards#index epic_boards#show] },
            container_html_options: { class: 'home' },
            item_id: context.is_super_sidebar ? :epic_boards : :boards
          )
        end

        def roadmap_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Roadmap'),
            link: group_roadmap_path(context.group),
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::PlanMenu,
            active_routes: { path: 'roadmap#show' },
            container_html_options: { class: 'home' },
            item_id: :roadmap
          )
        end
      end
    end
  end
end
