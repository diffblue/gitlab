# frozen_string_literal: true

module Projects
  module LearnGitlabHelper
    IMAGE_PATH_PLAN = "learn_gitlab/section_plan.svg"
    IMAGE_PATH_DEPLOY = "learn_gitlab/section_deploy.svg"
    IMAGE_PATH_WORKSPACE = "learn_gitlab/section_workspace.svg"
    LICENSE_SCANNING_RUN_URL = 'https://docs.gitlab.com/ee/user/compliance/license_compliance/index.html'
    GITLAB_COM = 'gitlab.com'
    ONBOARDING_START_TRIAL = 'onboarding-start-trial'
    ONBOARDING_REQUIRE_MR_APPROVALS = 'onboarding-require-merge-approvals'
    ONBOARDING_CODE_OWNERS = 'onboarding-code-owners'

    def learn_gitlab_data(project)
      {
        actions: onboarding_actions_data(project).to_json,
        sections: onboarding_sections_data.to_json,
        project: onboarding_project_data(project).to_json
      }
    end

    def learn_gitlab_onboarding_available?(namespace)
      Onboarding::LearnGitlab.new(current_user).onboarding_and_available?(namespace)
    end

    private

    def onboarding_actions_data(project)
      onboarding_progress = Onboarding::Progress.find_by(namespace: project.namespace) # rubocop: disable CodeReuse/ActiveRecord
      attributes = onboarding_progress.attributes.symbolize_keys

      data = action_urls(project).to_h do |action, url|
        [
          action,
          {
            url: url,
            completed: attributes[Onboarding::Progress.column_name(action)].present?,
            enabled: true
          }
        ]
      end

      if ::Gitlab::CurrentSettings.should_check_namespace_plan? && !can_start_trial?(project)
        data[:trial_started][:enabled] = false
        data[:trial_started][:message] =
          s_('LearnGitlab|Contact your administrator to start a free Ultimate trial.')
      end

      data
    end

    def can_start_trial?(project)
      root = project.root_ancestor
      root.has_free_or_no_subscription? && can?(current_user, :admin_namespace, root)
    end

    def onboarding_sections_data
      {
        workspace: {
          svg: image_path(IMAGE_PATH_WORKSPACE)
        },
        plan: {
          svg: image_path(IMAGE_PATH_PLAN)
        },
        deploy: {
          svg: image_path(IMAGE_PATH_DEPLOY)
        }
      }
    end

    def onboarding_project_data(project)
      { name: project.name }
    end

    def action_urls(project)
      urls = action_issue_urls(project).merge(
        issue_created: project_issues_path(project),
        git_write: project_path(project),
        merge_request_created: project_merge_requests_path(project),
        user_added: project_members_url(project),
        **deploy_section_action_urls(project)
      )

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

    def new_trial_path_with_glm(content:, source: GITLAB_COM)
      new_trial_path({ glm_source: source, glm_content: content })
    end

    def action_issue_urls(project)
      Onboarding::Completion::ACTION_ISSUE_IDS.transform_values do |id|
        project_issue_url(project, id)
      end
    end

    def deploy_section_action_urls(project)
      experiment(
        :security_actions_continuous_onboarding,
        namespace: project.namespace,
        user: current_user,
        sticky_to: current_user
      ) do |e|
        e.control { { security_scan_enabled: project_security_configuration_path(project) } }
        e.candidate do
          {
            license_scanning_run: LICENSE_SCANNING_RUN_URL,
            secure_dependency_scanning_run: project_security_configuration_path(project, anchor: 'dependency-scanning'),
            secure_dast_run: project_security_configuration_path(project, anchor: 'dast')
          }
        end
      end.run
    end
  end
end
