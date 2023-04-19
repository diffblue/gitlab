# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::LearnGitlabHelper, feature_category: :onboarding do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '#learn_gitlab_data' do
    let_it_be(:namespace) { create(:group) }
    let_it_be(:project) { build_stubbed(:project, namespace: namespace) }
    let(:onboarding_actions_data) { Gitlab::Json.parse(learn_gitlab_data[:actions]).deep_symbolize_keys }
    let(:onboarding_sections_data) { Gitlab::Json.parse(learn_gitlab_data[:sections], symbolize_names: true) }
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
          :license_scanning_run,
          :secure_dependency_scanning_run,
          :secure_dast_run,
          :code_added
        ]

        expect(onboarding_actions_data.keys).to contain_exactly(*expected_keys)
      end

      it 'has all section data', :aggregate_failures do
        expect(onboarding_sections_data.map(&:keys)).to match_array([[:code], [:workspace, :plan, :deploy]])
        expect(onboarding_sections_data.first.values.map(&:keys)).to match_array([[:svg]])
        expect(onboarding_sections_data.second.values.map(&:keys)).to match_array([[:svg]] * 3)
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
        license_scanning_run: a_hash_including(completed: false),
        secure_dependency_scanning_run: a_hash_including(completed: false),
        secure_dast_run: a_hash_including(completed: false),
        code_added: a_hash_including(completed: false)
      }

      expect(onboarding_actions_data).to match(result)
    end

    it 'sets correct paths' do
      result = {
        trial_started: a_hash_including(url: %r{/#{project.name}/-/project_members\z}),
        pipeline_created: a_hash_including(url: %r{/#{project.name}/-/pipelines\z}),
        issue_created: a_hash_including(url: %r{/#{project.name}/-/issues\z}),
        git_write: a_hash_including(url: %r{/#{project.name}\z}),
        user_added: a_hash_including(url: %r{#\z}),
        merge_request_created: a_hash_including(url: %r{/#{project.name}/-/merge_requests\z}),
        code_added: a_hash_including(url: %r{/-/ide/project/#{project.full_path}/edit\z}),
        code_owners_enabled: a_hash_including(url: %r{/user/project/code_owners#set-up-code-owners\z}),
        required_mr_approvals_enabled: a_hash_including(
          url: %r{/ci/pipelines/settings#coverage-check-approval-rule\z}
        ),
        license_scanning_run: a_hash_including(
          url: help_page_path(described_class::LICENSE_SCANNING_RUN_PATH)
        ),
        secure_dependency_scanning_run: a_hash_including(
          url: project_security_configuration_path(project, anchor: 'dependency-scanning')
        ),
        secure_dast_run: a_hash_including(
          url: project_security_configuration_path(project, anchor: 'dast')
        )
      }

      expect(onboarding_actions_data).to match(result)
    end

    context 'for trial- and subscription-related actions' do
      let(:disabled_message) { s_('LearnGitlab|Contact your administrator to start a free Ultimate trial.') }

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

  describe '#onboarding_track_label' do
    where(:params, :result) do
      lazy { { trial_onboarding_flow: 'true' } }  | 'trial_registration'
      lazy { { trial_onboarding_flow: 'false' } } | 'free_registration'
      lazy { {} }                                 | 'free_registration'
    end

    with_them do
      it 'returns free_registration' do
        allow(helper).to receive(:params).and_return(params)

        expect(helper.onboarding_track_label).to eq(result)
      end
    end
  end
end
