# frozen_string_literal: true

module Sidebars
  module Projects
    module SuperSidebarMenus
      class CodeMenu < ::Sidebars::Menu
        override :title
        def title
          s_('Navigation|Code')
        end

        override :sprite_icon
        def sprite_icon
          'code'
        end
      end
    end
  end
end
