# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class TrialWidgetMenu < ::Sidebars::Menu
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
            root_group: root_group,
            trial_status: trial_status,
            ultimate_plan_id: ultimate_plan_id
          }
        end

        private

        def root_group
          context.group.root_ancestor
        end

        def trial_status
          GitlabSubscriptions::TrialStatus.new(root_group.trial_starts_on, root_group.trial_ends_on)
        end

        def ultimate_plan_id
          # supplying plan here rejects any free plans so we won't get that data returned
          plans = GitlabSubscriptions::FetchSubscriptionPlansService.new(plan: :free).execute

          return unless plans

          plans.find { |data| data['code'] == 'ultimate' }&.fetch('id', nil)
        end
      end
    end
  end
end
