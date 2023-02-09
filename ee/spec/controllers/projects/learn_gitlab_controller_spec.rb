# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::LearnGitlabController, feature_category: :onboarding do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: create(:group)) }

  describe 'GET #show' do
    let_it_be(:learn_gitlab_project) do
      create(:project, name: Onboarding::LearnGitlab::PROJECT_NAME).tap do |record|
        record.add_maintainer(user)
      end
    end

    let_it_be(:board) { create(:board, project: learn_gitlab_project, name: Onboarding::LearnGitlab::BOARD_NAME) }
    let(:params) { { namespace_id: project.namespace.to_param, project_id: project } }

    subject(:action) { get :show, params: params }

    before_all do
      project.namespace.add_owner(user)
      create(:label, project: learn_gitlab_project, name: Onboarding::LearnGitlab::LABEL_NAME)
      create(:onboarding_progress, namespace: project.namespace)
    end

    context 'for unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
    end

    context 'for authenticated user' do
      before do
        sign_in(user)
      end

      it { is_expected.to render_template(:show) }

      context 'when learn_gitlab is not available' do
        before do
          board.update!(name: 'bogus')
        end

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      context 'with invite_for_help_continuous_onboarding experiment' do
        it 'tracks the assignment', :experiment do
          stub_experiments(invite_for_help_continuous_onboarding: true)

          expect(experiment(:invite_for_help_continuous_onboarding))
            .to track(:assignment).with_context(namespace: project.namespace).on_next_instance

          action
        end
      end
    end
  end

  describe 'GET #onboarding' do
    let(:extra_params) { {} }

    subject(:onboarding) do
      get :onboarding, params: { namespace_id: project.namespace.to_param, project_id: project }.merge(extra_params)
    end

    context 'without a signed in user' do
      it { is_expected.to redirect_to new_user_session_path }
    end

    context 'with an owner user signed in' do
      before do
        sign_in(user)
        project.namespace.add_owner(user)
      end

      it { is_expected.to render_template(:onboarding) }

      it 'sets the correct session key' do
        onboarding

        expect(cookies[:confetti_post_signup]).to eq('true')
      end

      it 'tracks render event' do
        onboarding

        expect_snowplow_event(
          category: described_class.name,
          action: 'onboarding',
          user: user,
          label: 'free_registration'
        )
      end

      context 'when in trial onboarding flow' do
        let(:extra_params) { { trial_onboarding_flow: true } }

        it 'tracks the action event' do
          onboarding

          expect_snowplow_event(
            category: described_class.name,
            action: 'onboarding',
            user: user,
            label: 'trial_registration'
          )
        end
      end
    end

    context 'with a non-owner user signed in' do
      before do
        sign_in(user)
        project.namespace.add_maintainer(user)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }

      it 'does not track the action event' do
        onboarding

        expect_no_snowplow_event(
          category: described_class.name,
          action: 'onboarding',
          user: user,
          label: 'free_registration'
        )
      end
    end
  end
end
