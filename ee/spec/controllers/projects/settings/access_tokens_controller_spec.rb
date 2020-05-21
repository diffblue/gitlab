# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::AccessTokensController, :saas do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group_with_plan, plan: :bronze_plan) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:bot_user) { create(:user, :project_bot) }

  before do
    allow(Gitlab).to receive(:com?).and_return(true)
    stub_ee_application_setting(should_check_namespace_plan: true)
    sign_in(user)
  end

  before_all do
    project.add_maintainer(bot_user)
    project.add_maintainer(user)
  end

  shared_examples 'feature unavailable' do
    context 'with a free plan' do
      let(:group) { create(:group_with_plan, plan: :free_plan) }
      let(:project) { create(:project, group: group) }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when user is not a maintainer with a paid group plan' do
      before do
        project.add_developer(user)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end
  end

  describe '#index' do
    subject { get :index, params: { namespace_id: project.namespace, project_id: project } }

    it_behaves_like 'feature unavailable'
    it_behaves_like 'project access tokens available #index'
  end

  describe '#create' do
    let_it_be(:access_token_params) { { name: 'Nerd bot', scopes: ["api"], expires_at: Date.today + 1.month } }

    subject { post :create, params: { namespace_id: project.namespace, project_id: project }.merge(project_access_token: access_token_params) }

    it_behaves_like 'feature unavailable'
    it_behaves_like 'project access tokens available #create'
  end

  describe '#revoke', :sidekiq_inline do
    let(:project_access_token) { create(:personal_access_token, user: bot_user) }

    subject { put :revoke, params: { namespace_id: project.namespace, project_id: project, id: project_access_token } }

    it_behaves_like 'feature unavailable'
    it_behaves_like 'project access tokens available #revoke'
  end
end
