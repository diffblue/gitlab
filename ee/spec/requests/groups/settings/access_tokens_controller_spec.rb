# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Settings::AccessTokensController, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:resource) { create(:group) }

  before_all do
    resource.add_owner(user)
  end

  before do
    sign_in(user)
    stub_licensed_features(resource_access_token: true)
  end

  describe 'POST /:namespace/-/settings/access_tokens' do
    let(:access_token_params) { { name: 'Nerd bot', scopes: ["api"], expires_at: Date.today + 1.month } }
    let(:ultimate_plan) { build(:ultimate_plan) }

    subject(:request) do
      post group_settings_access_tokens_path(resource), params: { resource_access_token: access_token_params }
    end

    context 'when has trial subscription', :saas do
      before do
        create(:gitlab_subscription, :active_trial, namespace: resource, hosted_plan: ultimate_plan)
      end

      it 'cannot create token' do
        expect { request }.not_to change { PersonalAccessToken.count }
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when has non-trial subscription', :saas do
      before do
        create(:gitlab_subscription, namespace: resource, hosted_plan: ultimate_plan)
      end

      it 'can create token' do
        expect { request }.to change { PersonalAccessToken.count }.from(0).to(1)
        expect(response).to have_gitlab_http_status(:success)
      end
    end
  end
end
