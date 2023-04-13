# frozen_string_literal: true

module Sidebars
  module Admin
    module Menus
      class PushRulesMenu < ::Sidebars::Admin::BaseMenu
        override :link
        def link
          admin_push_rule_path
        end

        override :title
        def title
          s_('Admin|Push Rules')
        end

        override :sprite_icon
        def sprite_icon
          'push-rules'
        end

        override :render?
        def render?
          !!context.current_user&.can_admin_all_resources? &&
            License.feature_available?(:push_rules)
        end

        override :active_routes
        def active_routes
          { controller: :push_rules }
        end
      end
    end
  end
end
