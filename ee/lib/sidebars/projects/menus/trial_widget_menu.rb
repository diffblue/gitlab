# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class TrialWidgetMenu < ::Sidebars::Groups::Menus::TrialWidgetMenu
        private

        def root_group
          context.project.namespace.root_ancestor
        end
      end
    end
  end
end
