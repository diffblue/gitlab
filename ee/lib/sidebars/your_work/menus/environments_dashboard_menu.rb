# frozen_string_literal: true

module Sidebars
  module YourWork
    module Menus
      class EnvironmentsDashboardMenu < ::Sidebars::Menu
        override :link
        def link
          operations_environments_path
        end

        override :title
        def title
          context.is_super_sidebar ? _('Environments') : _('Environments Dashboard')
        end

        override :sprite_icon
        def sprite_icon
          'environment'
        end

        override :render?
        def render?
          can?(context.current_user, :read_operations_dashboard)
        end

        override :active_routes
        def active_routes
          { path: 'operations#environments' }
        end
      end
    end
  end
end
