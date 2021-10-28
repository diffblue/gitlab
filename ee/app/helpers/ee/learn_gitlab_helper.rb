# frozen_string_literal: true

module EE
  module LearnGitlabHelper
    extend ::Gitlab::Utils::Override

    GITLAB_COM = 'gitlab.com'
    ONBOARDING_START_TRIAL = 'onboarding-start-trial'
    ONBOARDING_REQUIRE_MR_APPROVALS = 'onboarding-require-merge-approvals'
    ONBOARDING_CODE_OWNERS = 'onboarding-code-owners'

    private

    override :new_action_urls
    def new_action_urls(project)
      urls = super(project)

      return urls unless ::Gitlab::CurrentSettings.should_check_namespace_plan?

      glm_params = { glm_source: GITLAB_COM }

      urls.merge(
        trial_started: new_trial_path(glm_params.merge(glm_content: ONBOARDING_START_TRIAL)),
        required_mr_approvals_enabled: new_trial_path(glm_params.merge(glm_content: ONBOARDING_REQUIRE_MR_APPROVALS)),
        code_owners_enabled: new_trial_path(glm_params.merge(glm_content: ONBOARDING_CODE_OWNERS))
      )
    end
  end
end
