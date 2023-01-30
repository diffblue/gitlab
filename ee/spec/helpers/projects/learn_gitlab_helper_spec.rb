# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::LearnGitlabHelper, feature_category: :onboarding do
  let_it_be(:user) { create(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '#learn_gitlab_data' do
    let_it_be(:namespace) { create(:group) }
    let_it_be(:project) { build_stubbed(:project, name: Onboarding::LearnGitlab::PROJECT_NAME, namespace: namespace) }
    let(:onboarding_actions_data) { Gitlab::Json.parse(learn_gitlab_data[:actions]).deep_symbolize_keys }
    let(:onboarding_sections_data) { Gitlab::Json.parse(learn_gitlab_data[:sections]).deep_symbolize_keys }
    let(:onboarding_project_data) { Gitlab::Json.parse(learn_gitlab_data[:project]).deep_symbolize_keys }

    before do
      Onboarding::Progress.onboard(namespace)
      Onboarding::Progress.register(namespace, :git_write)
    end

    subject(:learn_gitlab_data) { helper.learn_gitlab_data(project) }

    shared_examples 'has all data' do
      it 'has all actions' do
        expected_keys = [
          :issue_created,
          :git_write,
          :pipeline_created,
          :merge_request_created,
          :user_added,
          :trial_started,
          :required_mr_approvals_enabled,
          :code_owners_enabled,
          :security_scan_enabled
        ]

        expect(onboarding_actions_data.keys).to contain_exactly(*expected_keys)
      end

      it 'has all section data', :aggregate_failures do
        expect(onboarding_sections_data.keys).to contain_exactly(:deploy, :plan, :workspace)
        expect(onboarding_sections_data.values.map(&:keys)).to match_array([[:svg]] * 3)
      end

      it 'has all project data', :aggregate_failures do
        expect(onboarding_project_data.keys).to contain_exactly(:name)
        expect(onboarding_project_data.values).to match_array([project.name])
      end
    end

    it_behaves_like 'has all data'

    it 'sets correct completion statuses' do
      result = {
        issue_created: a_hash_including(completed: false),
        git_write: a_hash_including(completed: true),
        pipeline_created: a_hash_including(completed: false),
        merge_request_created: a_hash_including(completed: false),
        user_added: a_hash_including(completed: false),
        trial_started: a_hash_including(completed: false),
        required_mr_approvals_enabled: a_hash_including(completed: false),
        code_owners_enabled: a_hash_including(completed: false),
        security_scan_enabled: a_hash_including(completed: false)
      }

      expect(onboarding_actions_data).to match(result)
    end

    context 'with security_actions_continuous_onboarding experiment' do
      let(:base_paths) do
        {
          trial_started: a_hash_including(url: %r{/learn_gitlab/-/issues/2\z}),
          pipeline_created: a_hash_including(url: %r{/learn_gitlab/-/issues/7\z}),
          code_owners_enabled: a_hash_including(url: %r{/learn_gitlab/-/issues/10\z}),
          required_mr_approvals_enabled: a_hash_including(url: %r{/learn_gitlab/-/issues/11\z}),
          issue_created: a_hash_including(url: %r{/learn_gitlab/-/issues\z}),
          git_write: a_hash_including(url: %r{/learn_gitlab\z}),
          user_added: a_hash_including(url: %r{/learn_gitlab/-/project_members\z}),
          merge_request_created: a_hash_including(url: %r{/learn_gitlab/-/merge_requests\z})
        }
      end

      context 'when control' do
        before do
          stub_experiments(security_actions_continuous_onboarding: :control)
        end

        it 'sets correct paths' do
          result = base_paths.merge(
            security_scan_enabled: a_hash_including(
              url: %r{/learn_gitlab/-/security/configuration\z}
            )
          )

          expect(onboarding_actions_data).to match(result)
        end
      end

      context 'when candidate' do
        before do
          stub_experiments(security_actions_continuous_onboarding: :candidate)
        end

        it 'sets correct paths' do
          result = base_paths.merge(
            license_scanning_run: a_hash_including(
              url: described_class::LICENSE_SCANNING_RUN_URL
            ),
            secure_dependency_scanning_run: a_hash_including(
              url: project_security_configuration_path(project, anchor: 'dependency-scanning')
            ),
            secure_dast_run: a_hash_including(
              url: project_security_configuration_path(project, anchor: 'dast')
            )
          )

          expect(onboarding_actions_data).to match(result)
        end
      end
    end

    context 'for trial- and subscription-related actions' do
      let(:disabled_message) { s_('LearnGitlab|Contact your administrator to start a free Ultimate trial.') }

      context 'when namespace plans are not enabled' do
        before do
          stub_application_setting(check_namespace_plan: false)
        end

        it 'provides the default URLs' do
          result = {
            trial_started: a_hash_including(
              url: a_string_matching(%r{#{namespace.path}/learn_gitlab/-/issues/2})
            ),
            code_owners_enabled: a_hash_including(
              url: a_string_matching(%r{#{namespace.path}/learn_gitlab/-/issues/10})
            ),
            required_mr_approvals_enabled: a_hash_including(
              url: a_string_matching(%r{#{namespace.path}/learn_gitlab/-/issues/11})
            )
          }

          expect(onboarding_actions_data).to include(result)
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
            namespace.add_owner(user)
            result = {
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
            }

            expect(onboarding_actions_data).to include(result)
          end

          it 'provides URLs to Gitlab docs to namespace non-admins' do
            result = {
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
            }

            expect(onboarding_actions_data).to include(result)
          end
        end

        context 'when namespace has paid subscription' do
          before do
            allow(namespace).to receive(:has_free_or_no_subscription?).and_return(false)
          end

          it 'provides URLs to Gitlab docs to namespace admins' do
            namespace.add_owner(user)
            result = {
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
            }

            expect(onboarding_actions_data).to include(result)
          end

          it 'provides URLs to Gitlab docs to namespace non-admins' do
            result = {
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
            }

            expect(onboarding_actions_data).to include(result)
          end
        end
      end
    end
  end

  describe '#learn_gitlab_onboarding_available?' do
    let(:namespace) { build(:group) }

    it 'is not available' do
      expect(helper.learn_gitlab_onboarding_available?(namespace)).to eq(false)
    end

    it 'is available' do
      allow_next_instance_of(Onboarding::LearnGitlab, user) do |instance|
        allow(instance).to receive(:onboarding_and_available?).with(namespace).and_return(true)
      end

      expect(helper.learn_gitlab_onboarding_available?(namespace)).to eq(true)
    end
  end
end
