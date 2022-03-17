# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LearnGitlabHelper do
  include Devise::Test::ControllerHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, name: LearnGitlab::Project::PROJECT_NAME, namespace: user.namespace) }
  let_it_be(:namespace) { project.namespace }

  before do
    allow_next_instance_of(LearnGitlab::Project) do |learn_gitlab|
      allow(learn_gitlab).to receive(:project).and_return(project)
    end

    OnboardingProgress.onboard(namespace)
  end

  describe '#learn_gitlab_data' do
    subject(:onboarding_actions_data) do
      Gitlab::Json.parse(helper.learn_gitlab_data(project)[:actions]).deep_symbolize_keys
    end

    context 'when in the new action URLs experiment' do
      context 'for trial- and subscription-related actions' do
        context 'when namespace plans are not enabled' do
          before do
            stub_application_setting(check_namespace_plan: false)
          end

          it 'provides the default URLs' do
            expect(onboarding_actions_data).to include(
              trial_started: a_hash_including(
                url: a_string_matching(%r{#{namespace.path}/learn_gitlab/-/issues/2})
              ),
              code_owners_enabled: a_hash_including(
                url: a_string_matching(%r{#{namespace.path}/learn_gitlab/-/issues/10})
              ),
              required_mr_approvals_enabled: a_hash_including(
                url: a_string_matching(%r{#{namespace.path}/learn_gitlab/-/issues/11})
              )
            )
          end
        end

        context 'when namespace plans are enabled' do
          before do
            stub_application_setting(check_namespace_plan: true)
          end

          it 'provides URLs to start a trial for the appropariate actions' do
            expect(onboarding_actions_data).to include(
              trial_started: a_hash_including(
                url: new_trial_path(glm_source: 'gitlab.com', glm_content: 'onboarding-start-trial')
              ),
              code_owners_enabled: a_hash_including(
                url: new_trial_path(glm_source: 'gitlab.com', glm_content: 'onboarding-code-owners')
              ),
              required_mr_approvals_enabled: a_hash_including(
                url: new_trial_path(glm_source: 'gitlab.com', glm_content: 'onboarding-require-merge-approvals')
              )
            )
          end
        end
      end
    end
  end
end
