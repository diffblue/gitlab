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

    def cross_stage_fdm_highlighted_features
      [
        {
          icon_name: 'epic',
          title: s_('InProductMarketing|Epics'),
          desc: s_('InProductMarketing|Make it easier to collaborate on high-level ideas by grouping related issues in an epic.')
        },
        {
          icon_name: 'agile',
          title: s_('InProductMarketing|Roadmaps'),
          desc: s_('InProductMarketing|Visualize your epics and milestones in a timeline.')
        },
        {
          icon_name: 'agile',
          title: s_('InProductMarketing|Scoped labels'),
          desc: s_('InProductMarketing|Create well-defined workflows by using scoped labels on issues, merge requests, and epics. Labels with the same scope cannot be used together, which prevents conflicts.')
        },
        {
          icon_name: 'chart-line',
          title: s_('InProductMarketing|Burn up/down charts'),
          desc: s_('InProductMarketing|Track completed issues in a chart, so you can see how a milestone is progressing at a glance.')
        },
        {
          icon_name: 'merge-request',
          title: s_('InProductMarketing|Merge request approval rule'),
          desc: s_('InProductMarketing|Keep your code quality high by defining who should approve merge requests and how many approvals are required.')
        },
        {
          icon_name: 'user',
          title: s_('InProductMarketing|Code owners'),
          desc: s_('InProductMarketing|Define who owns specific files or directories, so the right reviewers are suggested when a merge request introduces changes to those files.')
        },
        {
          icon_name: 'chart-bar',
          title: s_('InProductMarketing|Code review analytics'),
          desc: s_('InProductMarketing|Find and fix bottlenecks in your code review process by understanding how long open merge requests have been in review.')
        },
        {
          icon_name: 'magnifying-glass',
          title: s_('InProductMarketing|Multiple required approvers'),
          desc: s_("InProductMarketing|Require multiple approvers on a merge request, so you know it's in good shape before it's merged.")
        },
        {
          icon_name: 'shield-check',
          title: s_('InProductMarketing|Dependency scanning'),
          desc: s_('InProductMarketing|Find out if your external libraries are safe. Run dependency scanning jobs that check for known vulnerabilities in your external libraries.')
        },
        {
          icon_name: 'cloud-check',
          title: s_('InProductMarketing|Dynamic application security testing'),
          desc: s_('InProductMarketing|Protect your web application by using DAST to examine for vulnerabilities in deployed environments.')
        }
      ]
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
