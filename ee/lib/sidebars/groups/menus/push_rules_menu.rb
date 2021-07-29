# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class PushRulesMenu < ::Sidebars::Menu
        override :link
        def link
          edit_group_push_rules_path(context.group)
        end

        override :title
        def title
          _('Push Rules')
        end

        override :sprite_icon
        def sprite_icon
          'push-rules'
        end

        override :render?
        def render?
          can?(context.current_user, :change_push_rules, context.group)
        end

        override :active_routes
        def active_routes
          { controller: :push_rules }
        end
      end
    end
  end
end
