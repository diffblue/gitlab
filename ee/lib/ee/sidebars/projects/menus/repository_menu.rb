# frozen_string_literal: true

module EE
  module Sidebars
    module Projects
      module Menus
        module RepositoryMenu
          extend ::Gitlab::Utils::Override

          override :configure_menu_items
          def configure_menu_items
            return false unless super

            add_item(file_locks_menu_item)

            true
          end

          private

          def file_locks_menu_item
            unless context.project.licensed_feature_available?(:file_locks)
              return ::Sidebars::NilMenuItem.new(item_id: :file_locks)
            end

            ::Sidebars::MenuItem.new(
              title: _('Locked files'),
              link: project_path_locks_path(context.project),
              super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::CodeMenu,
              active_routes: { controller: :path_locks },
              item_id: :file_locks
            )
          end
        end
      end
    end
  end
end
