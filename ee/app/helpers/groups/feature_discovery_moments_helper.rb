# frozen_string_literal: true

module Groups
  module FeatureDiscoveryMomentsHelper
    def show_cross_stage_fdm?(root_group)
      return false unless Gitlab::CurrentSettings.should_check_namespace_plan?
      return false unless root_group&.persisted?
      return false unless root_group.plan_eligible_for_trial?

      can?(current_user, :admin_group, root_group)
    end

    def cross_stage_fdm_glm_params
      {
        glm_source: 'gitlab.com',
        glm_content: 'cross_stage_fdm'
      }
    end
  end
end
