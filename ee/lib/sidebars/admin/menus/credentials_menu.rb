# frozen_string_literal: true

module Sidebars
  module Admin
    module Menus
      class CredentialsMenu < ::Sidebars::Admin::BaseMenu
        override :link
        def link
          admin_credentials_path
        end

        override :title
        def title
          s_('Admin|Credentials')
        end

        override :sprite_icon
        def sprite_icon
          'lock'
        end

        override :render?
        def render?
          !!context.current_user&.can_admin_all_resources? &&
            License.feature_available?(:credentials_inventory)
        end

        override :active_routes
        def active_routes
          { controller: :credentials }
        end
      end
    end
  end
end
