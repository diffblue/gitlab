# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class TrialExperimentMenu < ::Sidebars::Groups::Menus::TrialExperimentMenu
        private

        def root_group
          context.project.namespace.root_ancestor
        end
      end
    end
  end
end
