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

    def cross_stage_fdm_value_statements
      [
        {
          icon_name: 'collaboration',
          title: s_('InProductMarketing|Collaboration made easy'),
          desc: s_('InProductMarketing|Break down silos to coordinate seamlessly across development, operations, and security with a consistent experience across the development lifecycle.')
        },
        {
          icon_name: 'cog-code',
          title: s_('InProductMarketing|Lower cost of development'),
          desc: s_('InProductMarketing|A single application eliminates complex integrations, data chokepoints, and toolchain maintenance, resulting in greater productivity and lower cost.')
        },
        {
          icon_name: 'cog-check',
          title: s_('InProductMarketing|Your software, deployed your way'),
          desc: s_('InProductMarketing|GitLab is infrastructure agnostic (supporting GCP, AWS, Azure, OpenShift, VMWare, On Prem, Bare Metal, and more), offering a consistent workflow experience – irrespective of the environment.')
        }
      ]
    end
  end
end
