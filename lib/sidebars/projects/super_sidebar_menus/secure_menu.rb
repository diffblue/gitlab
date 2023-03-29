# frozen_string_literal: true

module Sidebars
  module Projects
    module SuperSidebarMenus
      class SecureMenu < ::Sidebars::Menu
        override :title
        def title
          s_('SidebarNavigation|Secure')
        end

        override :sprite_icon
        def sprite_icon
          'shield'
        end
      end
    end
  end
end
