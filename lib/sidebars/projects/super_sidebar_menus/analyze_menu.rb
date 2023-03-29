# frozen_string_literal: true

module Sidebars
  module Projects
    module SuperSidebarMenus
      class AnalyzeMenu < ::Sidebars::Menu
        override :title
        def title
          s_('SidebarNavigation|Analyze')
        end

        override :sprite_icon
        def sprite_icon
          'chart'
        end
      end
    end
  end
end
