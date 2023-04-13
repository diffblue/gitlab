# frozen_string_literal: true

module Sidebars
  module Admin
    module Menus
      class SubscriptionMenu < ::Sidebars::Admin::BaseMenu
        override :link
        def link
          admin_subscription_path
        end

        override :title
        def title
          s_('Admin|Subscription')
        end

        override :sprite_icon
        def sprite_icon
          'license'
        end

        override :extra_container_html_options
        def extra_container_html_options
          { 'data-qa-selector': 'admin_subscription_menu_link' }
        end

        override :active_routes
        def active_routes
          { controller: :subscriptions }
        end
      end
    end
  end
end
