# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::AccessTokensController, :saas, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:resource) { create(:project, group: group) }
  let_it_be(:access_token_user) { create(:user, :project_bot) }

  before do
    allow(Gitlab).to receive(:com?).and_return(true)
    stub_ee_application_setting(should_check_namespace_plan: true)
    sign_in(user)
  end

  before_all do
    resource.add_maintainer(access_token_user)
    resource.add_maintainer(user)
  end

  shared_examples 'feature unavailable' do
    context 'with a free plan' do
      let(:group) { create(:group_with_plan, plan: :free_plan) }
      let(:resource) { create(:project, group: group) }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when user is not a maintainer with a paid group plan' do
      before do
        resource.add_developer(user)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end
  end

  describe 'POST /:namespace/:project/-/settings/access_tokens' do
    let_it_be(:access_token_params) { { name: 'Nerd bot', scopes: ["api"], expires_at: Date.today + 1.month } }

    subject(:request) do
      post project_settings_access_tokens_path(resource), params: { resource_access_token: access_token_params }
      response
    end

    context 'when has a bronze subscription' do
      before_all do
        create(:gitlab_subscription, :bronze, namespace: group)
      end

      it_behaves_like 'feature unavailable'
      it_behaves_like 'POST resource access tokens available'
    end

    context 'when has an active trial subscription' do
      before_all do
        create(:plan_limits, :ultimate_trial_plan, project_access_token_limit: 1)
        create(:gitlab_subscription, :ultimate_trial, namespace: group)
      end

      it 'can create first token successfully' do
        expect { request }.to change { PersonalAccessToken.count }.from(0).to(1)
        expect(response).to have_gitlab_http_status(:success)
      end

      it 'cannot create second token' do
        create(:personal_access_token, user: access_token_user)

        expect { request }.not_to change { PersonalAccessToken.count }
        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end

      context 'when there is token under different project of same group' do
        let(:another_project) { build(:project, group: group) }

        subject(:request) do
          post project_settings_access_tokens_path(another_project),
            params: { resource_access_token: access_token_params }
          response
        end

        before do
          another_project.add_maintainer(user)
        end

        it 'still cannot create new token' do
          create(:personal_access_token, user: access_token_user)

          expect { request }.not_to change { PersonalAccessToken.count }
          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'PUT /:namespace/:project/-/settings/access_tokens/:id/revoke', :sidekiq_inline do
    let(:resource_access_token) { create(:personal_access_token, user: access_token_user) }

    subject(:request) do
      put revoke_project_settings_access_token_path(resource, resource_access_token)
      response
    end

    it_behaves_like 'feature unavailable'
    it_behaves_like 'PUT resource access tokens available'

    context 'when has trial subscription' do
      context 'when the trial subscription is active' do
        before do
          create(:gitlab_subscription, :ultimate_trial, namespace: group)
        end

        it 'can revoke token successfully' do
          request

          expect(resource.reload.bots).not_to include(access_token_user)
        end
      end

      context 'when the trial subscription is expired' do
        before do
          create(:gitlab_subscription, :expired_trial, :free, namespace: group)
        end

        it 'still can revoke token successfully' do
          request

          expect(resource.reload.bots).not_to include(access_token_user)
        end
      end
    end
  end
end
