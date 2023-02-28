# frozen_string_literal: true

module Sidebars
  module YourWork
    module Menus
      class OperationsDashboardMenu < ::Sidebars::Menu
        override :link
        def link
          operations_path
        end

        override :title
        def title
          context.is_super_sidebar ? _('Operations') : _('Operations Dashboard')
        end

        override :sprite_icon
        def sprite_icon
          'cloud-gear'
        end

        override :render?
        def render?
          can?(context.current_user, :read_operations_dashboard)
        end

        override :active_routes
        def active_routes
          { path: 'operations#index' }
        end
      end
    end
  end
end
