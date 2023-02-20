# frozen_string_literal: true

module Sidebars
  module UserSettings
    module Menus
      class ProfileBillingMenu < ::Sidebars::Menu
        override :link
        def link
          profile_billings_path
        end

        override :title
        def title
          _('Billing')
        end

        override :sprite_icon
        def sprite_icon
          'credit-card'
        end

        override :render?
        def render?
          !!context.current_user && ::Gitlab::CurrentSettings.should_check_namespace_plan?
        end

        override :active_routes
        def active_routes
          { controller: :billings }
        end
      end
    end
  end
end
