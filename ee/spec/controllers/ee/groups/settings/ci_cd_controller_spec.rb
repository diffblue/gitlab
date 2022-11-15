# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Settings::CiCdController, feature_category: :continuous_integration do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context 'as an owner' do
    before do
      group.add_owner(user)
    end

    describe 'GET #show' do
      let!(:group_protected_environment) { create(:protected_environment, :production, :group_level, group: group) }

      it 'renders group protected environments' do
        get :show, params: { group_id: group }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)

        expect(subject.view_assigns['protected_environments']).to match_array([group_protected_environment])
      end

      it 'excludes the deployment tier from dropdown if a corresponding environment is protected' do
        get :show, params: { group_id: group }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)

        expect(subject.view_assigns['tiers']).to include(staging: 1, testing: 2, development: 3, other: 4)
      end
    end
  end
end
