# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LearnGitlabHelper do
  include Devise::Test::ControllerHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, name: Onboarding::LearnGitlab::PROJECT_NAME, namespace: user.namespace) }
  let_it_be(:namespace) { project.namespace }
  let(:disabled_message) { s_('LearnGitlab|Contact your administrator to start a free Ultimate trial.') }

  before do
    allow_next_instance_of(Onboarding::LearnGitlab) do |learn_gitlab|
      allow(learn_gitlab).to receive(:project).and_return(project)
    end

    Onboarding::Progress.onboard(namespace)
    sign_in(user)
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

          context 'when namespace has free or no subscription' do
            before do
              allow(namespace).to receive(:has_free_or_no_subscription?).and_return(true)
            end

            it 'provides URLs to start a trial to namespace admins' do
              allow(helper).to receive(:can?).with(user, :admin_namespace, namespace).and_return(true)
              expect(onboarding_actions_data).to include(
                trial_started: a_hash_including(
                  url: new_trial_path(glm_source: 'gitlab.com', glm_content: 'onboarding-start-trial'),
                  enabled: true
                ),
                code_owners_enabled: a_hash_including(
                  url: new_trial_path(glm_source: 'gitlab.com', glm_content: 'onboarding-code-owners'),
                  enabled: true
                ),
                required_mr_approvals_enabled: a_hash_including(
                  url: new_trial_path(glm_source: 'gitlab.com', glm_content: 'onboarding-require-merge-approvals'),
                  enabled: true
                )
              )
            end

            it 'provides URLs to Gitlab docs to namespace non-admins' do
              allow(helper).to receive(:can?).with(user, :admin_namespace, namespace).and_return(false)
              expect(onboarding_actions_data).to include(
                trial_started: a_hash_including(
                  url: project_project_members_path(project),
                  enabled: false,
                  message: disabled_message
                ),
                code_owners_enabled: a_hash_including(
                  url: help_page_path('user/project/code_owners', anchor: 'set-up-code-owners'),
                  enabled: true
                ),
                required_mr_approvals_enabled: a_hash_including(
                  url: help_page_path('ci/pipelines/settings', anchor: 'coverage-check-approval-rule'),
                  enabled: true
                )
              )
            end
          end

          context 'when namespace has paid subscription' do
            before do
              allow(namespace).to receive(:has_free_or_no_subscription?).and_return(false)
            end

            it 'provides URLs to Gitlab docs to namespace admins' do
              allow(helper).to receive(:can?).with(user, :admin_namespace, namespace).and_return(true)
              expect(onboarding_actions_data).to include(
                trial_started: a_hash_including(
                  url: project_project_members_path(project),
                  enabled: false,
                  message: disabled_message
                ),
                code_owners_enabled: a_hash_including(
                  url: help_page_path('user/project/code_owners', anchor: 'set-up-code-owners'),
                  enabled: true
                ),
                required_mr_approvals_enabled: a_hash_including(
                  url: help_page_path('ci/pipelines/settings', anchor: 'coverage-check-approval-rule'),
                  enabled: true
                )
              )
            end

            it 'provides URLs to Gitlab docs to namespace non-admins' do
              allow(helper).to receive(:can?).with(user, :admin_namespace, namespace).and_return(false)
              expect(onboarding_actions_data).to include(
                trial_started: a_hash_including(
                  url: project_project_members_path(project),
                  enabled: false,
                  message: disabled_message
                ),
                code_owners_enabled: a_hash_including(
                  url: help_page_path('user/project/code_owners', anchor: 'set-up-code-owners'),
                  enabled: true
                ),
                required_mr_approvals_enabled: a_hash_including(
                  url: help_page_path('ci/pipelines/settings', anchor: 'coverage-check-approval-rule'),
                  enabled: true
                )
              )
            end
          end
        end
      end
    end
  end
end
