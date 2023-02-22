# frozen_string_literal: true

module Sidebars
  module Security
    module Menus
      class SecurityDashboardMenu < ::Sidebars::Menu
        override :link
        def link
          security_dashboard_path
        end

        override :title
        def title
          _('Security Dashboard')
        end

        override :sprite_icon
        def sprite_icon
          'dashboard'
        end

        override :render?
        def render?
          !!context.current_user
        end

        override :active_routes
        def active_routes
          { path: 'security/dashboard#show' }
        end
      end
    end
  end
end
