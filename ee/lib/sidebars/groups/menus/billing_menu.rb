# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class BillingMenu < ::Sidebars::Menu
        override :link
        def link
          group_billings_path(root_group, from: :side_nav)
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
          ::Gitlab::CurrentSettings.should_check_namespace_plan? &&
            can?(context.current_user, :admin_namespace, root_group) &&
            !root_group.user_namespace?
        end

        override :extra_container_html_options
        def extra_container_html_options
          {
            class: 'shortcuts-billings'
          }
        end

        override :extra_nav_link_html_options
        def extra_nav_link_html_options
          {
            data: {
              track_action: :render,
              track_experiment: :billing_in_side_nav
            }
          }
        end

        override :active_routes
        def active_routes
          { page: group_billings_path(root_group, from: :side_nav) }
        end

        private

        def root_group
          context.group.root_ancestor
        end
      end
    end
  end
end
