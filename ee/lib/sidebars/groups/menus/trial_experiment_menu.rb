# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class TrialExperimentMenu < ::Sidebars::Menu
        override :menu_partial
        def menu_partial
          'layouts/nav/sidebar/group_trial_status_widget'
        end

        override :menu_partial_options
        def menu_partial_options
          {
            group: context.group
          }
        end
      end
    end
  end
end
