# frozen_string_literal: true

module EE
  module LearnGitlabHelper
    extend ::Gitlab::Utils::Override

    GITLAB_COM = 'gitlab.com'
    ONBOARDING_START_TRIAL = 'onboarding-start-trial'
    ONBOARDING_REQUIRE_MR_APPROVALS = 'onboarding-require-merge-approvals'
    ONBOARDING_CODE_OWNERS = 'onboarding-code-owners'

    private

    override :action_urls
    def action_urls(project)
      urls = super(project)

      return urls unless ::Gitlab::CurrentSettings.should_check_namespace_plan?

      trial_items = {
        trial_started: project_project_members_path(project),
        required_mr_approvals_enabled: help_page_path('ci/pipelines/settings', anchor: 'coverage-check-approval-rule'),
        code_owners_enabled: help_page_path('user/project/code_owners', anchor: 'set-up-code-owners')
      }

      if can_start_trial?(project)
        trial_items = {
          trial_started: new_trial_path_with_glm(content: ONBOARDING_START_TRIAL),
          required_mr_approvals_enabled: new_trial_path_with_glm(content: ONBOARDING_REQUIRE_MR_APPROVALS),
          code_owners_enabled: new_trial_path_with_glm(content: ONBOARDING_CODE_OWNERS)
        }
      end

      urls.merge(trial_items)
    end

    override :onboarding_actions_data
    def onboarding_actions_data(project)
      action_urls = super(project)

      if ::Gitlab::CurrentSettings.should_check_namespace_plan? && !can_start_trial?(project)
        action_urls[:trial_started][:enabled] = false
        action_urls[:trial_started][:message] =
          s_('LearnGitlab|Contact your administrator to start a free Ultimate trial.')
      end

      action_urls
    end

    def can_start_trial?(project)
      root = project&.root_ancestor
      root&.has_free_or_no_subscription? && can?(current_user, :admin_namespace, root)
    end

    def new_trial_path_with_glm(content:, source: GITLAB_COM)
      new_trial_path({ glm_source: source, glm_content: content })
    end
  end
end
