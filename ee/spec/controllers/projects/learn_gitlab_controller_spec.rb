# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::LearnGitlabController, feature_category: :onboarding do
  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:group) }
  let_it_be(:project) { create(:project, namespace: namespace) }

  describe 'GET #show' do
    let(:params) { { namespace_id: namespace.to_param, project_id: project } }

    subject(:action) { get :show, params: params }

    before_all do
      namespace.add_owner(user)
    end

    context 'for unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
    end

    context 'for authenticated user' do
      before do
        sign_in(user)
      end

      context 'when learn gitlab is available' do
        before do
          create(:onboarding_progress, namespace: namespace)
        end

        it { is_expected.to render_template(:show) }
      end

      context 'when learn_gitlab is not available' do
        it { is_expected.to have_gitlab_http_status(:not_found) }
      end
    end
  end

  describe 'GET #onboarding' do
    let(:extra_params) { {} }

    subject(:onboarding) do
      get :onboarding, params: { namespace_id: namespace.to_param, project_id: project }.merge(extra_params)
    end

    context 'without a signed in user' do
      it { is_expected.to redirect_to new_user_session_path }
    end

    context 'with an owner user signed in' do
      before do
        sign_in(user)
        namespace.add_owner(user)
      end

      it { is_expected.to render_template(:onboarding) }

      it 'sets the correct session key' do
        onboarding

        expect(cookies[:confetti_post_signup]).to eq('true')
      end
    end

    context 'with a non-owner user signed in' do
      before do
        sign_in(user)
        namespace.add_maintainer(user)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end
  end
end
