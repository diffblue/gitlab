# frozen_string_literal: true

module Sidebars
  module Admin
    module Menus
      class GeoMenu < ::Sidebars::Admin::BaseMenu
        override :configure_menu_items
        def configure_menu_items
          add_item(geo_sites_menu_item)
          add_item(geo_settings_menu_item)

          true
        end

        override :title
        def title
          s_('Admin|Geo')
        end

        override :sprite_icon
        def sprite_icon
          'location-dot'
        end

        override :extra_container_html_options
        def extra_container_html_options
          { testid: 'admin-geo-menu-link' }
        end

        private

        def geo_sites_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Sites'),
            link: admin_geo_nodes_path,
            active_routes: { controller: %w[admin/geo/nodes admin/geo/projects admin/geo/uploads
              admin/geo/designs admin/geo/replicables] },
            item_id: :geo_nodes,
            container_html_options: { title: _('Sites') }
          )
        end

        def geo_settings_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Settings'),
            link: admin_geo_settings_path,
            active_routes: { path: 'admin/geo/settings#show' },
            item_id: :geo_settings,
            container_html_options: { title: 'Settings' }
          )
        end
      end
    end
  end
end
