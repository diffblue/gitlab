# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::AccessTokensController, :saas, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group_with_plan, plan: :bronze_plan) }
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

    subject do
      post project_settings_access_tokens_path(resource), params: { resource_access_token: access_token_params }
      response
    end

    it_behaves_like 'feature unavailable'
    it_behaves_like 'POST resource access tokens available'
  end

  describe 'PUT /:namespace/:project/-/settings/access_tokens/:id', :sidekiq_inline do
    let(:resource_access_token) { create(:personal_access_token, user: access_token_user) }

    subject do
      put revoke_project_settings_access_token_path(resource, resource_access_token)
      response
    end

    it_behaves_like 'feature unavailable'
    it_behaves_like 'PUT resource access tokens available'
  end
end
