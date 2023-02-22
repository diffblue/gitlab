# frozen_string_literal: true

module Sidebars
  module Security
    module Menus
      class SettingsMenu < ::Sidebars::Menu
        override :link
        def link
          settings_security_dashboard_path
        end

        override :title
        def title
          _('Settings')
        end

        override :sprite_icon
        def sprite_icon
          'settings'
        end

        override :render?
        def render?
          !!context.current_user
        end

        override :active_routes
        def active_routes
          { path: 'security/dashboard#settings' }
        end
      end
    end
  end
end
