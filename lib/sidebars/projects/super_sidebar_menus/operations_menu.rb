# frozen_string_literal: true

module Sidebars
  module Projects
    module SuperSidebarMenus
      class OperationsMenu < ::Sidebars::Menu
        override :title
        def title
          s_('Navigation|Operate')
        end

        override :sprite_icon
        def sprite_icon
          'deployments'
        end
      end
    end
  end
end
