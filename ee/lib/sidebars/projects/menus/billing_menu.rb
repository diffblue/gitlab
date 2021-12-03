# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class BillingMenu < ::Sidebars::Groups::Menus::BillingMenu
        private

        def root_group
          context.project.namespace.root_ancestor
        end
      end
    end
  end
end
