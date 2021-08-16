# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class WikiMenu < ::Sidebars::Menu
        override :link
        def link
          context.group.wiki.web_url
        end

        override :extra_container_html_options
        def extra_container_html_options
          {
            class: 'shortcuts-wiki'
          }
        end

        override :title
        def title
          _('Wiki')
        end

        override :sprite_icon
        def sprite_icon
          'book'
        end

        override :render?
        def render?
          can?(context.current_user, :read_wiki, context.group)
        end

        override :active_routes
        def active_routes
          { controller: :wikis }
        end
      end
    end
  end
end
