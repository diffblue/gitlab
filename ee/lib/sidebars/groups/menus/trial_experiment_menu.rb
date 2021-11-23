# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class TrialExperimentMenu < ::Sidebars::Menu
        override :render?
        def render?
          # Only top-level groups can have trials & plans
          ::Gitlab::CurrentSettings.should_check_namespace_plan? &&
            root_group.trial_active? &&
            can?(current_user, :admin_namespace, root_group)
        end

        override :menu_partial
        def menu_partial
          'layouts/nav/sidebar/group_trial_status_widget'
        end

        override :menu_partial_options
        def menu_partial_options
          {
            root_group: root_group
          }
        end

        private

        def root_group
          context.group.root_ancestor
        end
      end
    end
  end
end
